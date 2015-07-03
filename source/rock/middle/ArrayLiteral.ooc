import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, Expression, FunctionCall, Block,
       VariableDecl, VariableAccess, Cast, Node, ClassDecl, TypeDecl, BaseType,
       Statement, IntLiteral, BinaryOp, Block, ArrayCreation, FunctionCall,
       FunctionDecl
import tinker/[Response, Resolver, Trail, Errors]
import algo/typeAnalysis
import structs/[List, ArrayList]

ArrayLiteral: class extends Literal {

    readyToUnwrap := true
    unwrapped := false
    elements := ArrayList<Expression> new()
    type : Type = null

    init: func ~arrayLiteral (.token) {
        super(token)
    }

    clone: func -> This {
        copy := new(token)
        elements each(|e| copy elements add(e clone()))
        copy
    }

    getElements: func -> List<Expression> { elements }

    accept: func (visitor: Visitor) {
        visitor visitArrayLiteral(this)
    }

    getType: func -> Type { type }

    toString: func -> String {
        if(elements empty?()) return "[]"

        buffer := Buffer new()
        if (type) {
            buffer append("(arrayType="). append(type toString()). append(")")
        } else {
            buffer append("(arrayType=unknown)")
        }
        buffer append('[')
        isFirst := true
        for(element in elements) {
            if(isFirst) isFirst = false
            else        buffer append(", ")
            buffer append(element toString())
        }
        buffer append(']')
        buffer toString()
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        readyToUnwrap = true

        {
            result := inferType(trail, res)
            match result {
                case -1 =>
                    res wholeAgain(this, "need something to resolve to infer array literal type, or just replaced")
                    return Response OK
                case 2 =>
                    return Response LOOP
            }
        }

        // resolve all elements
        trail push(this)
        for(element in elements) {
            response := element resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)

        // if we still don't know our type, resolve from elements' innerTypes
        if(type == null && !elements empty?()) {
            baseType := elements first() getType()
            if(!baseType || !baseType isResolved()) {
                res wholeAgain(this, "need base type")
                return Response OK
            }

            for(i in 1 .. elements getSize()) {
                currType := elements get(i) getType()
                if(!currType || !currType isResolved()) {
                    res wholeAgain(this, "need element type")
                    return Response OK
                }

                root := findCommonRoot(baseType, currType)
                if(!root) {
                    if(res fatal) {
                        res throwError(IncompatibleType new(elements get(i) token,\
                            "Type %s is incompatible with the inferred type of the array literal %s" format(currType toString(), baseType toString())))
                    } else {
                        res wholeAgain(this, "need resolved refs for all types")
                    }
                    return Response OK
                }
                baseType = root
            }

            type = ArrayType new(baseType, IntLiteral new(elements size, token), token)
        }

        if(type != null) {
            response := type resolve(trail, res)
            if(!response ok()) return response
        }

        if(readyToUnwrap && type instanceOf?(ArrayType)) {
            return unwrapToArrayInit(trail, res)
        }

        return Response OK

    }

    /**
     * @return -1 if we're waiting for something to resolve or got replaced, 0 if we can't
     * infer from context, 1 if we got the type, 2 if we've been replaced
     */
    inferType: func (trail: Trail, res: Resolver) -> Int {

        // bitchjump casts and infer type from them, if they're there (damn you, j/ooc)
        {
            parentIdx := 1
            parent := trail peek(parentIdx)
            shouldReplace := false

            outerType: Type = match parent {
                case cast: Cast =>
                    parentIdx += 1
                    shouldReplace = true
                    cast getType()
                case vDecl: VariableDecl =>
                    parentIdx += 1
                    vDecl getType()
                case binOp: BinaryOp =>
                    parentIdx += 1
                    binOp left getType()
                case =>
                    null
            }

            if (outerType != null) {
                if (outerType getRef() == null) {
                    // needs outerType to resolve
                    return -1
                }

                isGood := match outerType {
                    case s: SugarType =>
                        true
                    case b: BaseType =>
                        hasTypeArgs := !b typeArgs empty?()
                        if (hasTypeArgs) {
                            baseType := b typeArgs first() inner
                            outerType = ArrayType new(baseType, IntLiteral new(elements size, token), token)

                            vDecl := VariableDecl new(outerType, generateTempName("arrLitOp"), this, token)
                            trail addBeforeInScope(this, vDecl)
                            parent replace(this, VariableAccess new(vDecl, token))
                            type = outerType

                            return 2 // need to loop
                        }
                        hasTypeArgs
                    case =>
                        false
                }

                if (isGood && (type == null || !type equals?(outerType))) {
                    type = outerType clone()

                    if (shouldReplace) {
                        readyToUnwrap = false
                        grandpa := trail peek(parentIdx)
                        grandpa replace(parent, this)
                        // just replaced
                        return 2
                    } else {
                        return 1
                    }
                }
            }
        }

        // infer type from parent function call, if any, and add an implicit cast
        {
            parent := trail peek()
            if(parent instanceOf?(FunctionCall)) {
                fCall := parent as FunctionCall
                if(fCall refScore > 0) {
                    index := fCall args indexOf(this)
                    if(index != -1) {
                        if(fCall getRef() == null) {
                            res wholeAgain(this, "Need call ref to infer type")
                            readyToUnwrap = false
                        } else if(fCall getRef() args getSize() > index) {
                            targetType := fCall getRef() args get(index) getType()
                            if((type == null || !type equals?(targetType)) &&
                               (!targetType instanceOf?(SugarType) || !targetType as SugarType inner isGeneric())) {
                                cast := Cast new(this, targetType, token)
                                if(!parent replace(this, cast)) {
                                    res throwError(CouldntReplace new(token, this, cast, trail))
                                }
                                // added implicit cast, trail is no longer valid
                                return 2
                            }
                        } else {
                            "%s is the %dth argument of %s, ref is %s with %d arguments" printfln(\
                                toString(), index, fCall toString(), fCall getRef() toString(), fCall getRef() args getSize())
                        }
                    }
                }
            }
        }

        // could not infer
        return 0
    }

    /**
        unwrap something like:

            array := [1, 2, 3]

        to something like:

            arrLit := [1, 2, 3] as Int*
            array := Int[3] new()
            memcpy(array data, arrLit, Int size * 3)

    */
    unwrapToArrayInit: func (trail: Trail, res: Resolver) -> Response {

        arrType := match type {
            case null =>
                message := "Trying to unwrap to array init with non-array type: %s" format(type toString())
                res throwError(InternalError new(token, message))
                null as ArrayType
            case at: ArrayType =>
                if (!at expr) {
                    at expr = IntLiteral new(elements size, token)
                }
                at
        }

        // set to true if a VDFE should become a simple VD with
        // explicit initialization in getDefaultsFunc()/getLoadFunc()
        // this happens when the order of initialization becomes
        // important, especially when casting an array literal to an ArrayList
        memberInitShouldMove := false

        // check outer var-decl
        varDeclIdx := trail find(VariableDecl)
        if(varDeclIdx != -1) {
            memberDecl := trail get(varDeclIdx) as VariableDecl
            if(memberDecl getType() == null) {
                res wholeAgain(this, "need memberDecl type")
                return Response OK
            }
        }

        // bitch-jump casts
        parentIdx := 1
        parent := trail peek(parentIdx)
        while(parent instanceOf?(Cast)) {
            parentIdx += 1
            parent = trail peek(parentIdx)
        }

        vDecl : VariableDecl = null
        vAcc : VariableAccess = null

        if(parent instanceOf?(VariableDecl)) {
            vDecl = parent as VariableDecl
            vAcc = VariableAccess new(vDecl, token)
            if(vDecl isMember()) {
                vAcc expr = vDecl isStatic() ? VariableAccess new(vDecl owner getNonMeta() getInstanceType(), token) : VariableAccess new("this", token)
            }
        } else {
            vDecl = VariableDecl new(null, generateTempName("arrLit"), token)
            vAcc = VariableAccess new(vDecl, token)
            if(vDecl isMember()) {
                vAcc expr = vDecl isStatic() ? VariableAccess new(vDecl owner getNonMeta() getInstanceType(), token) : VariableAccess new("this", token)
            }
            if(!trail addBeforeInScope(this, vDecl)) {
                grandpa := trail peek(parentIdx + 2)
                memberDecl := (varDeclIdx != -1 ? trail get(varDeclIdx) as VariableDecl : null)

                if(grandpa instanceOf?(ClassDecl)) {
                    cDecl := grandpa as ClassDecl
                    fDecl: FunctionDecl
                    if(memberDecl isStatic()) {
                        fDecl = cDecl getLoadFunc()
                    } else {
                        fDecl = cDecl getDefaultsFunc()
                    }
                    fDecl getBody() add(vDecl)
                    memberInitShouldMove = true
                } else {
                    if(res fatal) res throwError(CouldntAddBeforeInScope new(token, this, vDecl, trail))
                    res wholeAgain(this, "Trail is messed up, gotta loop")
                    return Response OK
                }
            }
            if(!parent replace(this, vAcc)) {
                if(res fatal) res throwError(CouldntReplace new(token, this, vAcc, trail))
                res wholeAgain(this, "Trail is messed up, gotta loop.")
                return Response OK
            }
        }

        vDecl setType(null)
        vDecl setExpr(ArrayCreation new(arrType, true, token))
        ptrType := match (arrType inner) {
            case aType: ArrayType =>
                PointerType new(arrType exprLessClone(), token)
            case =>
                PointerType new(arrType inner, token)
        }
        ptrDecl := VariableDecl new(ptrType, generateTempName("ptrLit"), this, token)

        // add memcpy from C-pointer literal block
        block := Block new(token)

        // if varDecl is our immediate parent
        success := false
        if(trail getSize() - varDeclIdx == 1) {
            success = trail addAfterInScope(vDecl, block)
        } else {
            success = trail addBeforeInScope(this, block)
        }

        if(!success) {
            grandpa := trail get(varDeclIdx - 1)
            memberDecl := trail get(varDeclIdx) as VariableDecl

            if(grandpa instanceOf?(ClassDecl)) {
                cDecl := grandpa as ClassDecl
                fDecl: FunctionDecl
                if(memberDecl isStatic()) {
                    fDecl = cDecl getLoadFunc()
                } else {
                    fDecl = cDecl getDefaultsFunc()
                }
                fDecl getBody() add(block)

                if(memberInitShouldMove) {
                    // now we should move the 'expr' of our VariableDecl into fDecl's body,
                    // because order matters here.
                    if(memberDecl getType() == null) memberDecl setType(memberDecl expr getType()) // fixate type
                    memberAcc := VariableAccess new(memberDecl, token)
                    memberAcc expr = memberDecl isStatic() ? VariableAccess new(memberDecl owner getNonMeta() getInstanceType(), token) : VariableAccess new("this", token)

                    init := BinaryOp new(memberAcc, memberDecl expr, OpType ass, token)
                    fDecl getBody() add(init)
                    memberDecl setExpr(null)
                }
            } else {
                res throwError(CouldntAddAfterInScope new(token, (trail getSize() - varDeclIdx == 1) ? vDecl : this, block, trail))
            }
        }

        block getBody() add(ptrDecl)

        innerTypeAcc := VariableAccess new(arrType inner, token)

        sizeExpr : Expression = (arrType expr ? arrType expr : VariableAccess new(vAcc, "length", token))
        copySize := BinaryOp new(sizeExpr, VariableAccess new(innerTypeAcc, "size", token), OpType mul, token)

        memcpyCall := FunctionCall new("memcpy", token)
        memcpyCall args add(VariableAccess new(vAcc, "data", token))
        memcpyCall args add(VariableAccess new(ptrDecl, token))
        memcpyCall args add(copySize)
        block getBody() add(memcpyCall)

        type = PointerType new(arrType inner, arrType token)

        return Response LOOP

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        elements replace(oldie as Expression, kiddo as Expression)
    }

}

IncompatibleType: class extends Error {
    init: super func ~tokenMessage
}
