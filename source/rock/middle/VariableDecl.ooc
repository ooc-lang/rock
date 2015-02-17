import structs/[ArrayList]
import Type, Declaration, Expression, Visitor, TypeDecl, VariableAccess,
       Node, ClassDecl, FunctionCall, Argument, BinaryOp, Cast, Module,
       Block, Scope, FunctionDecl, Argument, BaseType, FuncType, Statement,
       NullLiteral, Tuple, TypeList, AddressOf
import tinker/[Response, Resolver, Trail, Errors]
import ../frontend/BuildParams

VariableDecl: class extends Declaration {

    name = "", fullName = null, doc = "" : String

    type: Type
    expr: Expression
    inferOnly? := false
    isGenerated := false
    owner: TypeDecl

    isArg := false
    isGlobal := false

    isConst := false
    isStatic := false
    isProto := false
    externName: String = null
    unmangledName: String = null

    /** if this VariableDecl is a Func, it can be called! */
    fDecl : FunctionDecl = null

    init: func ~vDecl (.type, .name, .token) {
        init(type, name, null, token)
    }

    init: func ~vDeclWithAtom (=type, =name, =expr, .token) {
        super(token)
    }

    init: func ~inferTypeOnly (=type, =name, =expr, .token) {
        inferOnly? = true
        super(token)
    }

    debugCondition: final func -> Bool {
        false
    }

    clone: func -> This {
        copy := new(type ? type clone() : null, name, expr ? expr clone() : null, token)
        cloneInto(copy)
    }

    cloneInto: func (copy: This) -> This {
        copy isArg         = isArg
        copy isGlobal      = isGlobal
        copy isConst       = isConst
        copy isProto       = isProto
        copy externName    = externName
        copy unmangledName = unmangledName
        copy fDecl         = fDecl
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitVariableDecl(this)
    }

    setType: func(=type) {}
    getType: func -> Type { type }


    getName: func -> String { name }

    toString: func -> String {
        "%s : %s%s" format(
            name,
            type ? type toString() : "<unknown type>",
            expr ? (" = " + expr toString()) : ""
        )
    }

    /**
     * If `true`, the property should not be added to the instance struct as a member.
     * Ordinary variables never are virtual. Properties can be.
     */
    isVirtual: func -> Bool { false }

    setOwner: func (=owner) {}
    getOwner: func -> TypeDecl { owner }

    setExpr: func (=expr) {}
    getExpr: func -> Expression { expr }

    isStatic: func -> Bool { isStatic }
    setStatic: func (=isStatic) {}

    isConst: func -> Bool { isConst }
    setConst: func (=isConst) {}

    isProto: func -> Bool { isProto }
    setProto: func (=isProto) { "%s is now proto!" format(name) println() }

    isGlobal: func -> Bool { isGlobal }
    setGlobal: func (=isGlobal) {}

    isArg: func -> Bool { isArg }

    getExternName: func -> String { externName }
    setExternName: func (=externName) {}
    isExtern: func -> Bool { externName != null }
    isExternWithName: func -> Bool {
        (externName != null) && !(externName empty?())
    }

    getUnmangledName: func -> String { unmangledName empty?() ? name : unmangledName }
    setUnmangledName: func (=unmangledName) {}
    isUnmangled: func -> Bool { unmangledName != null }
    isUnmangledWithName: func -> Bool {
        (unmangledName != null) && !(unmangledName empty?())
    }

    getFullName: func -> String {
        if(fullName == null) {
            if(isUnmangled()) {
                fullName = getUnmangledName()
            } else if(isExtern()) {
                if(isExternWithName()) {
                    fullName = externName
                } else {
                    fullName = name
                }
            } else {
                if(!isGlobal()) {
                    fullName = name
                } else {
                    fullName = "%s__%s" format(token module getUnderName(), name)
                }
            }
        }
        fullName
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        // FIXME: This, huh, shouldn't be needed at all, right?
        // ie. it should all be handled in Scope anyway, I think.
        if(name == access name) {
            access suggest(this)
        }

        0
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)

        if(debugCondition() || res params veryVerbose) {
            "Resolving variable decl %s\n" printfln(toString())
        }

        if(expr) {
            if(debugCondition()) ("Resolving expr " + expr toString()) println()
            response := expr resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        if(type == null && expr != null) {
            // infer the type
            type = expr getType()
            if(type == null) {
                trail pop(this)
                res wholeAgain(this, "must determine type of a VarDecl.")
                return Response OK
            }
            if(debugCondition()) {
                " >>> Just inferred type %s of %s from expr %s" format(type toString(), toString(), expr toString()) println()
            }
        }

        if(type != null) {
            if(debugCondition() || res params veryVerbose) {
                ("For " + toString() + ", resolving type " + type toString() + ", of type " + type class name) println()
            }
            response := type resolve(trail, res)
            if(debugCondition()) "Done resolving the type, ref = %s" printfln(type getRef() ? type getRef() toString() : "nil")
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        if(fDecl != null) {
            if(debugCondition()) "Resolving the fDecl." println()
            response := fDecl resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
            if(debugCondition()) "Done resolving the fDecl" println()
        }

        // Check if the expression's type inherits from our type 
        // and add a Cast in that case. (Fixes compiler warnings.)
        // Example: "a: Node = EmptyNode new()
        // => "a: Node = EmptyNode new() as Node

        if (type && expr) {
            exprType := expr getType()
            if (!exprType) {
                trail pop(this)
                res wholeAgain(this, "Need type of an Expression.")
                return Response OK
            }
            if (exprType inheritsFrom?(type)) {
                expr = Cast new(expr, type, token)
            }
        }

        trail pop(this)

        parent := trail peek()
        {
            if(!parent isScope() && !parent instanceOf?(TypeDecl) && !parent instanceOf?(FuncType)) {
                if(debugCondition()) "Parent isn't scope nor typedecl, unwrapping." println()
                varAcc := VariableAccess new(this, token)
                result := trail peek() replace(this, varAcc)
                if(!result) {
                    res throwError(CouldntReplace new(token, this, varAcc, trail))
                    return Response LOOP
                }

                idx := trail findScope()
                scope := trail get(idx) as Scope

                parent := trail get(idx + 1, Node)

                if(parent instanceOf?(FunctionCall)) {
                    result = trail addBeforeInScope(parent as Statement, this)
                } else {
                    block := Block new(token)
                    block getBody() add(this)
                    block getBody() add(parent as Statement)

                    result = scope replace(trail get(idx + 1), block)
                }

                if(!result) {
                    res throwError(InternalError new(token, "Couldn't unwrap " + toString() + " , trail = " + trail toString()))
                }

                res wholeAgain(this, "parent isn't scope nor typedecl, unwrapped")
                return Response LOOP
            }
        }

        if(expr != null) {
            if(debugCondition()) "Expr isn't null, handling generic calls" println()
            realExpr := expr
            while(realExpr instanceOf?(Cast)) {
                realExpr = realExpr as Cast inner
            }
            if(realExpr instanceOf?(FunctionCall)) {
                fCall := realExpr as FunctionCall
                fDecl := fCall getRef()
                if(!fDecl || !fDecl getReturnType() isResolved()) {
                    res wholeAgain(this, "fCall isn't resolved.")
                    return Response OK
                }

                if(!fDecl getReturnArgs() empty?()) {
                    if(fDecl getReturnType() instanceOf?(TypeList)) {
                        type = fDecl getReturnType() as TypeList types get(0)
                    }
                    ass := BinaryOp new(VariableAccess new(this, token), realExpr, OpType ass, token)
                    if(!trail addAfterInScope(this, ass)) {
                        res throwError(CouldntAddAfterInScope new(token, this, ass, trail))
                    }
                    expr = null
                }
            }
        } else { // Set pointer references to null
            if(debugCondition()) "Expr is null, set pointer reference to null" println()
            if (!owner && trail peek() instanceOf?(Scope)) { // don't touch a member-variable or an argument
                t := getType()
                if (!t) {
                    res wholeAgain(this, "Need Type.")
                    return Response OK
                }
                reference := t getRef()
                if (!reference || !getType()) {
                    res wholeAgain(this, "Need reference.")
                    return Response OK
                }
                if (t isPointer() || reference instanceOf?(ClassDecl)) { // Pointer OR object
                    expr = NullLiteral new(token)
                }
            }
        }

        if(!isArg && type != null && type isGeneric() && type pointerLevel() == 0) {
            if(debugCondition()) "Generic, set expr to malloc" println()
            if(expr != null) {
                if(expr instanceOf?(FunctionCall) && expr as FunctionCall getName() == "gc_malloc") return Response OK

                ass := BinaryOp new(VariableAccess new(this, token), expr, OpType ass, token)
                if(!trail addAfterInScope(this, ass)) {
                    res throwError(CouldntAddAfterInScope new(token, this, ass, trail))
                }
                expr = null
            }
            fCall := FunctionCall new("gc_malloc", token)
            tAccess := VariableAccess new(type getName(), token)
            sizeAccess := VariableAccess new(tAccess, "size", token)
            fCall getArguments() add(sizeAccess)
            expr = fCall
            res wholeAgain(this, "just set expr to gc_malloc cause generic!")
        }

        if(expr != null && !isLegal(res)) {
            res throwError(IncompatibleInit new(token, "Incompatible type in initialization: %s initialized to a %s\n" format(
                type toString(), expr getType() toString())))
            return Response OK
        }

        if(inferOnly?) expr = null

        if(debugCondition()) "Done resolving!" println()

        return Response OK

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo; true
            case type => type = kiddo; true
            case => false
        }
    }

    getFunctionDecl: func -> FunctionDecl {
        if(fDecl == null) {
            if(getType() instanceOf?(FuncType)) {
                fType := getType() as FuncType
                fDecl = FunctionDecl new(name, token)
                if(owner) fDecl setOwner(owner)
                if(fType typeArgs != null && !fType typeArgs empty?()) {
                    classType := BaseType new("Class", fType token)
                    if(fType typeArgs) for(typeArg in fType typeArgs) fDecl addTypeArg(typeArg)
                }
                for(argType in fType argTypes) {
                    fDecl args add(Argument new(argType, "", token))
                }
                if(fType varArg != VarArgType NONE) {
                    fDecl args add(VarArg new(token, fType varArg == VarArgType OOC ? "" : null))
                }
                if(fType returnType != null) {
                    fDecl setReturnType(fType returnType)
                }
                fDecl vDecl = this
            } else if(getType() getName() == "Closure") {
                fDecl = FunctionDecl new(name, token)
                fDecl args add(VarArg new(token, null))
                fDecl vDecl = this
            }
        }
        return fDecl
    }

    isMember: func -> Bool { owner != null }

    isLegal: func (res: Resolver) -> Bool {
        (lType, rType) := (type, expr getType())

        if(lType == null || lType getRef() == null || rType == null || rType getRef() == null) {
            // must resolve first
            res wholeAgain(this, "Unresolved types in vDecl, looping to determine legitness")
            return true
        }

        (lRef, rRef) := (lType getRef(), rType getRef())

        if(lRef instanceOf?(ClassDecl) && rRef instanceOf?(ClassDecl)) {
            if(!(
                (lType equals?(rType)) ||
                (rRef as ClassDecl inheritsFrom?(lRef as ClassDecl))
            )) {
                "Decl, l = %s, r = %s" printfln(lType toString(), rType toString())
                return false
            }
        }

        return true
    }

    /**
     * Given a trail and our depth into it, marks the variable declaration for partialing in upstream closures
     * If clsAccess is not null, it will also be added to the closure's CLS accesses
     */
    captureInUpstreamClosures: func (trail: Trail, depth: Int, clsAccess: VariableAccess = null) {
        closureIndex := trail find(FunctionDecl)

        if(closureIndex > depth) { // if it's not found (-1), this will be false anyway
            closure := trail get(closureIndex, FunctionDecl)
            mode := "v"
            if(closure isAnon()) {
                if(clsAccess) {
                    // In the case of an assignment or of getting the address of the variable in the ACS the
                    // variable should be captured by reference
                    bOpIDX := trail find(BinaryOp)
                    if(bOpIDX != -1) {
                        bOp := trail get(bOpIDX, BinaryOp)
                        if (bOp getLeft() == clsAccess && bOp isAssign()) mode = "r"
                    } else if((addrOfIDX := trail find(AddressOf)) != -1) {
                        addrOf := trail get(addrOfIDX, AddressOf)
                        if(addrOf expr == clsAccess) mode = "r"
                    }
                }

                // Find the first Scope that is the body of a function declaration in the top of the trail
                scopeDepth := closureIndex - 1
                while(scopeDepth > 0) {
                    maybeScope := trail get(scopeDepth, Node)
                    if(maybeScope instanceOf?(Scope)) {
                        scope := maybeScope as Scope
                        maybeClosure := trail get(scopeDepth - 1, Node)
                        if(maybeClosure instanceOf?(FunctionDecl)) {
                            closure := maybeClosure as FunctionDecl
                            // Find out if our access is between the kid closure and the parent closure
                            isDefined? := false
                            intermediateScopeIndex := closureIndex - 1
                            while(intermediateScopeIndex >= scopeDepth) {
                                interScope? := trail get(intermediateScopeIndex, Node)
                                if(interScope? instanceOf?(Scope)) {
                                    interScope := interScope? as Scope
                                    if(interScope list contains?(|stmt| stmt instanceOf?(VariableDecl) && stmt as VariableDecl name == name)) {
                                        isDefined? = true
                                    }
                                }
                                intermediateScopeIndex -= 1
                            }
                            // Only partial the variable in the top function if it has not be defined by it and it is not one of its arguments
                            if(closure isAnon && !closure args contains?(|arg| arg name == name || arg name == name + "_generic") \
                                && !isDefined?) {
                                // Mark the variable for partialing to top level closure
                                closure markForPartialing(this, mode)
                                if(clsAccess && !closure clsAccesses contains?(clsAccess)) {
                                    closure clsAccesses add(clsAccess)
                                }
                            }
                        }
                    }
                    scopeDepth -= 1
                }

                // If the variable has been defined in the closure body, we don't need to mark it for partialing
                definedInClosure? := closure getBody() list ? closure getBody() list contains?(this) : false
                if(closure isAnon && !isGlobal && !definedInClosure? &&
                    !closure args contains?(|arg| arg == this || arg name == this name + "_generic")) {
                    closure markForPartialing(this, mode)
                    if(clsAccess) closure clsAccesses add(clsAccess)
                }
            }
        }
    }

}

VariableDeclTuple: class extends VariableDecl {

    tuple: Tuple

    init: func ~vdTuple (.type, =tuple, .token) {
        init~vDecl (type, "<tuple>", token)
    }

    clone: func -> This {
        copy := new(type, tuple clone(), token)
        copy isArg         = isArg
        copy isGlobal      = isGlobal
        copy isConst       = isConst
        copy isProto       = isProto
        copy
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        if (expr) {
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)

            if (!response ok()) {
                return response
            }
        }

        match {
            case expr == null =>
                res throwError(InternalError new(token, "VariableDeclTuples need an expression. This should never happen"))

            case expr instanceOf?(Tuple) =>
                tuple2 := expr as Tuple
                if(tuple elements getSize() != tuple2 elements getSize()) {
                    res throwError(TupleMismatch new(token, "Incompatible tuples in multi-variable declaration."))
                    return Response OK
                }

                for(i in 0..tuple elements getSize()) {
                    element := tuple elements[i]
                    if(!element instanceOf?(VariableAccess)) {
                        res throwError(IncompatibleElementInTupleVarDecl new(element token, "Expected a variable access in a tuple-variable declaration!"))
                    }
                    argName := element as VariableAccess getName()

                    child := VariableDecl new(null, argName, tuple2 elements[i], token)

                    if(i == tuple elements getSize() - 1) {
                        // last? replace
                        if(!trail peek() replace(this, child)) {
                            res throwError(CouldntReplace new(token, this, child, trail))
                        }
                    } else {
                        // otherwise, add before
                        if(!trail addBeforeInScope(this, child)) {
                            res throwError(CouldntAddBeforeInScope new(token, this, child, trail))
                        }
                    }
                }
                return Response LOOP

            case expr instanceOf?(FunctionCall) =>
                fCall := expr as FunctionCall

                if(fCall getRef() == null) {
                    res wholeAgain(this, "Need fCall ref")
                    return Response OK
                }

                if(fCall getRef() getReturnArgs() empty?()) {
                    if(res fatal) {
                        res throwError(TupleMismatch new(token, "Need a multi-return function call as the expression of a tuple-variable declaration."))
                    }
                    res wholeAgain(this, "need multi-return func call")
                    return Response OK
                }

                returnType := fCall getRef() getReturnType() as TypeList
                returnTypes := returnType types

                j := 0
                for(element in tuple getElements()) {
                    match element {
                        case vAcc: VariableAccess =>
                            argName := vAcc getName()
                            if (argName == "_") {
                                // '_' are skipped
                            } else {
                                argType := returnTypes get(j)
                                argDecl := VariableDecl new(argType, argName, element token)
                                if(!trail addBeforeInScope(this, argDecl)) {
                                    res throwError(CouldntAddBeforeInScope new(token, this, argDecl, trail))
                                }
                                vAcc setRef(argDecl)
                            }
                    }
                    j += 1
                }

                assign := BinaryOp new(tuple, fCall, OpType ass, token)
                parent := trail peek()
                if (!parent replace(this, assign)) {
                    res throwError(CouldntReplace new(token, this, assign, trail))
                }
                res wholeAgain(this, "replaced decl with assignment")
            case =>
                res throwError(InternalError new(token, "Unsupported expression type %s for VariableDeclTuple." format(expr class name)))
        }

        Response OK
    }

}

TupleMismatch: class extends Error {
    init: super func ~tokenMessage
}

IncompatibleElementInTupleVarDecl: class extends Error {
    init: super func ~tokenMessage
}

IncompatibleInit: class extends Error {
    init: super func ~tokenMessage
}
