import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, Expression, FunctionCall, Block,
       VariableDecl, VariableAccess, Cast, Node, ClassDecl, TypeDecl, BaseType,
       Statement, IntLiteral, BinaryOp, Block, ArrayCreation, FunctionCall,
       FunctionDecl, CommaSequence, Scope
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

                            // vDecl := VariableDecl new(outerType, generateTempName("arrLitOp"), this, token)
                            // trail addBeforeInScope(this, vDecl)
                            // parent replace(this, VariableAccess new(vDecl, token))
                            type = outerType

                            // return 2 // need to loop
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

        seq := CommaSequence new(token)

        arrCrea := ArrayCreation new(arrType, true, token)
        arrLit := VariableDecl new(null, generateTempName("arrLit"), arrCrea, token)
        arrLit isGenerated = true
        arrAcc := VariableAccess new(arrLit, token)

        seq add(arrLit)

        parent := trail peek()
        if (!parent replace(this, seq)) {
            res throwError(CouldntReplace new(token, this, seq, trail))
        }

        ptrType := match (arrType inner) {
            case aType: ArrayType =>
                PointerType new(arrType exprLessClone(), token)
            case =>
                PointerType new(arrType inner, token)
        }
        ptrDecl := VariableDecl new(ptrType, generateTempName("ptrLit"), this, token)
        ptrDecl isGenerated = true
        seq add(ptrDecl)

        innerTypeAcc := VariableAccess new(arrType inner, token)

        sizeExpr : Expression = (arrType expr ? arrType expr : VariableAccess new(arrAcc, "length", token))
        copySize := BinaryOp new(sizeExpr, VariableAccess new(innerTypeAcc, "size", token), OpType mul, token)

        memcpyCall := FunctionCall new("memcpy", token)
        memcpyCall args add(VariableAccess new(arrAcc, "data", token))
        memcpyCall args add(VariableAccess new(ptrDecl, token))
        memcpyCall args add(copySize)
        seq add(memcpyCall)

        seq add(arrAcc)

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
