import ../frontend/[Token, BuildParams, AstBuilder], io/File
import BinaryOp, Visitor, Expression, VariableDecl, FunctionDecl,
       TypeDecl, Declaration, Type, Node, ClassDecl, NamespaceDecl,
       EnumDecl, PropertyDecl, FunctionCall, Module, Import, FuncType,
       NullLiteral, AddressOf, BaseType, StructLiteral, Return,
       Argument, Scope, CoverDecl, StringLiteral, Cast

import tinker/[Resolver, Response, Trail, Errors]
import structs/ArrayList

// for built-ins
import os/[System, Time], rock/RockVersion, rock/frontend/Target

VariableAccess: class extends Expression {

    _warned := false
    _staticFunc : FunctionDecl = null

    expr: Expression {
        get
        set (newExpr) {
            expr = newExpr
            match newExpr {
                case acc: VariableAccess => acc reverseExpr = this
            }
        }
    }

    reverseExpr: VariableAccess

    /** Name of the variable being accessed. */
    name: String

    prettyName: String { get {
      unbangify(name)
    } }

    ref: Declaration

    funcTypeDone := false

    init: func ~variableAccess (.name, .token) {
        init(null, name, token)
    }

    init: func ~variableAccessWithExpr (=expr, =name, .token) {
        super(token)
    }

    init: func ~varDecl (varDecl: VariableDecl, .token) {
        super(token)
        name = varDecl getName()
        ref = varDecl
    }

    clone: func -> This {
        new(expr ? expr clone() : null, name, token)
    }

    init: func ~typeAccess (type: Type, .token) {
        super(token)
        name = type getName()

        if (debugCondition()) {
            token printMessage("Building new typeAccess for #{type}, ref = #{type getRef()}")
            trap()
        }

        if(type getRef() instanceOf?(VariableDecl)) {
            varDecl := type getRef() as VariableDecl
            if(varDecl getOwner() != null) {
                if(varDecl isStatic) {
                    expr = VariableAccess new(varDecl getOwner() getInstanceType(), token)
                } else {
                    if (debugCondition()) {
                        token printMessage("That's where the 'this' comes from! owner is #{type owner ? type owner toString() : "<none>"}")
                    }
                    if (type owner) {
                        expr = type owner
                    } else {
                        // FIXME: ideally, this would never happen? 'owner' would just be 'this'
                        expr = VariableAccess new("this", token)
                    }
                }
            }
        } else {
            // else, it's safe to carry the ref
            ref = type getRef()
        }
    }

    accept: func (visitor: Visitor) {
        visitor visitVariableAccess(this)
    }

    // It's just an access, it has no side-effects whatsoever
    hasSideEffects : func -> Bool { false }

    debugCondition: final func -> Bool {
        false
    }

    suggest: func (node: Node) -> Bool {
        match node {
            case candidate: VariableDecl =>
                // if we're accessing a member, we're expecting the
                // candidate to belong to a TypeDecl..
                if(isMember() && !candidate isMember()) {
                    return false
                }

                if(_staticFunc && candidate isMember() && candidate == candidate owner thisDecl) {
                    //token formatMessage("Got thisDecl of " + candidate owner toString() + " in static func " + _staticFunc toString(), "INFO") println()

                    // Can't access an instance variable from static function
                    return false
                }

                ref = candidate
                if(isMember() && candidate owner isMeta) {
                    expr = VariableAccess new(candidate owner getNonMeta() getInstanceType(), candidate token)
                }

                true
            case candidate: FunctionDecl =>
                // if we're accessing a member, we're expecting the candidate
                // to belong to a TypeDecl..
                if((expr != null) && (candidate owner == null)) {
                    return false
                }

                ref = candidate
                true
            case tDecl: TypeDecl =>
                // TODO: the use of 'val' here is a workaround - an if/else should
                // be an expression.
                val := true
                if(tDecl isAddon()) {
                    // First rule of resolve club is: you do not resolve to an addon.
                    // Always resolve to the base instead.
                    val = suggest(tDecl getBase() getNonMeta())
                } else {
                    ref = node
                }
                val
            case nDecl: NamespaceDecl =>
                ref = node
                true
            case =>
                false
        }
    }

    refresh: func {
        // need to check again if our parent has changed
        funcTypeDone = false
    }

    isResolved: func -> Bool { ref != null && getType() != null && funcTypeDone }

    // TODO: oh boy.. this needs to be broken down into different methods

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if (isResolved()) {
            return Response OK
        }

        if(debugCondition() || res params veryVerbose) {
            "Access#resolve(%s). ref = %s inferred type = %s" printfln(prettyName, ref ? ("(%s) %s" format(ref class name, ref toString())) : "(nil)", getType() ? getType() toString() : "(nil)")
        }

        if(expr) {
            trail push(this)
            if (res params veryVerbose) {
                "Resolving expr %s for %s." printfln(expr toString(), toString())
            }

            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                return response
            }

            // don't go further until we know our expr is resolved
            if (!expr isResolved()) {
                res wholeAgain(this, "Waiting on our expr to resolve...")
                return Response OK
            }
        }

        // resolve built-ins first
        if (!expr) {
            builtin := getBuiltin(name)
            if (builtin) {
                if(!trail peek() replace(this, builtin)) {
                    res throwError(CouldntReplace new(token, this, builtin, trail))
                }
                res wholeAgain(this, "builtin replaced")
                return Response OK
            }
        }

        trail onOuter(FunctionDecl, |fDecl|
            if(fDecl isStatic()) _staticFunc = fDecl
        )

        if(expr && name == "class") {
            if(expr getType() == null || expr getType() getRef() == null) {
                res wholeAgain(this, "expr type or expr type ref is null")
                return Response OK
            }

            if(!expr getType() getRef() instanceOf?(ClassDecl)) {
                name = expr getType() getName()
                ref = expr getType() getRef()
                expr = null
            }
        }

        /*
         * Try to resolve the access from the expr
         */
        if(!ref && expr) {
            if (!expr isResolved()) {
                res wholeAgain(this, "waiting for expr to resolve..")
                return Response OK
            }

            if(expr instanceOf?(VariableAccess) && expr as VariableAccess getRef() != null \
              && expr as VariableAccess getRef() instanceOf?(NamespaceDecl)) {
                expr as VariableAccess getRef() resolveAccess(this, res, trail)
            } else {
                exprType := expr getType()
                if(exprType == null) {
                    res wholeAgain(this, "expr's type isn't resolved yet, and it's needed to resolve the access")
                    return Response OK
                }
                typeDecl := exprType getRef()
                if(!typeDecl) {
                    if(res fatal) res throwError(UnresolvedType new(expr token, expr getType(), "Can't resolve type %s" format(expr getType() toString())))
                    res wholeAgain(this, "unresolved access, looping")
                    return Response OK
                }

                typeDecl resolveAccess(this, res, trail)
                // We dont use pointerLevel or instanceOf? because we want accesses of an ArrayType to be legal
                if(exprType class == PointerType) {
                    res throwError(NeedsDeref new(this, "Can't access field '%s' in expression of pointer type '%s' without dereferencing it first" \
                                                           format(prettyName, exprType toString())))
                    return Response OK
                }
            }
        }

        /*
         * Try to resolve the access from the trail
         *
         * It's far simpler than resolving a function call, we just
         * explore the trail from top to bottom and retain the first match.
         */
        if(!ref && !expr) {
            depth := trail getSize() - 1
            while(depth >= 0) {
                node := trail get(depth)
                if(node instanceOf?(TypeDecl)) {
                    tDecl := node as TypeDecl
                    if(tDecl isMeta) node = tDecl getNonMeta()

                    // in initialization of a member object!
                    if(!ref && name == "this" && trail find(Scope) == -1) {
                        // nowadays, covers have __cover_defaults__ but they have
                        // by-ref this, for obvious reasons.
                        isThisRef := trail find(CoverDecl) != -1

                        suggest(isThisRef ? tDecl thisRefDecl : tDecl thisDecl)
                    }
                }
                status := node resolveAccess(this, res, trail)
                if (status == -1) {
                    res wholeAgain(this, "asked to wait while resolving access")
                    return Response OK
                }

                if(ref) {
                    if(expr) {
                        if(expr instanceOf?(VariableAccess)) {
                            trail push(this)
                            response := expr resolve(trail, res)
                            trail pop(this)
                            if(!response ok()) return Response LOOP
                            varAcc := expr as VariableAccess
                        }
                    }

                    // only accesses to variable decls need to be partialed (not type decls)
                    if(ref instanceOf?(VariableDecl) && !ref as VariableDecl isGlobal() && expr == null) {
                        ref as VariableDecl captureInUpstreamClosures(trail, depth, this)
                    }

                    break // break on first match
                }
                depth -= 1
            }
        }

        if (getType() instanceOf?(FuncType)) {
            fType := getType() as FuncType
            parent := trail peek()

            if (!fType isClosure) {
                closureType: FuncType = null
                if (debugCondition() || res params veryVerbose) {
                    "[funcTypeDone] doing our business for %s. parent = %s" printfln(toString(), parent toString())
                }

                if (parent instanceOf?(FunctionCall)) {
                    /*
                     * The case we're looking for is this one:
                     *
                     *     registerCallback(exit)
                     *
                     * If registerCallback is an ooc function and the arg is
                     * a FuncType we need to make a StructLiteral out of ourselves.
                     */
                    fCall := parent as FunctionCall
                    ourIndex := fCall args indexOf(this)

                    if (fCall refScore < -1) {
                        res wholeAgain(this, "waiting for parent function call to be resolved, to know if we should transform a functype access")
                        return Response OK
                    }
                    fDecl := fCall getRef()
                    // 1.) extern C functions don't accept a Closure_struct
                    // 2.) If ref is not a FDecl, it's probably
                    // already "closured" and doesn't need to be wrapped a second time
                    if (!fDecl isExtern() && ref instanceOf?(FunctionDecl)) {
                        if(fDecl args size <= ourIndex) {
                            res wholeAgain(this, "bad index for ref")
                            return Response OK
                        }
                        closureType = fDecl args get(ourIndex) getType()
                    } else {
                        if (debugCondition() || res params veryVerbose) {
                            "[funcTypeDone] for %s, in an extern C function, all good" printfln(toString())
                        }
                        funcTypeDone = true
                    }

                } else if (trail isRHS(this)) {
                    binOp := trail peek() as BinaryOp
                    lhsType := binOp left getType()
                    if(lhsType == null) {
                        res wholeAgain(this, "need type of BinOp's lhs")
                        return Response OK
                    }
                    closureType = lhsType clone()
                } else if (parent instanceOf?(Return)) {
                    fIndex := trail find(FunctionDecl)
                    if (fIndex != -1) {
                        closureType = trail get(fIndex, FunctionDecl) returnType clone()
                    }
                } else if (parent instanceOf?(VariableDecl)) {
                    /*
                    Handle the assignment of a first-class function.
                    Example:

                    f: func() {}
                    g := f

                    The right side needs to be a Closure having f and null as context.
                    */
                    p := parent as VariableDecl
                    if (p expr == this) {
                        closureType = ref getType()
                        if (!closureType) {
                            res wholeAgain(this, "need type of FDecl")
                            return Response OK
                        }
                    }
                } else {
                    // we're probably fine
                    if (debugCondition() || res params veryVerbose) {
                        "[funcTypeDone] %s not in a known suspect parent, probably good" printfln(toString())
                    }
                    funcTypeDone = true
                }

                if (closureType) {
                    if (closureType instanceOf?(FuncType)) {
                        fType isClosure = true

                        closureElements := [
                            this
                            NullLiteral new(token)
                        ] as ArrayList<VariableAccess>

                        closure := StructLiteral new(closureType, closureElements, token)
                        if(trail peek() replace(this, closure)) {
                            if (debugCondition() || res params veryVerbose) {
                                "[funcTypeDone] replaced %s with closure %s" printfln(toString(), closure toString())
                            }
                            funcTypeDone = true
                        } else {
                            res throwError(CouldntReplace new(token, this, closure, trail))
                        }
                    } else {
                        if (debugCondition() || res params veryVerbose) {
                            "[funcTypeDone] nothing to do for %s (closureType = %s)" printfln(toString(), closureType toString())
                        }
                        // probably a pointer, nothing to do here
                        funcTypeDone = true
                    }
                } else {
                    if (debugCondition() || res params veryVerbose) {
                        "[funcTypeDone] can't find closureType for %s" printfln(toString())
                    }
                }
            } else {
                if (debugCondition() || res params veryVerbose) {
                    "[funcTypeDone] nothing to do for %s (already a closure)" printfln(toString())
                }
                // already a closure
                funcTypeDone = true
            }

        } else {
            // not even a func type
            funcTypeDone = true
        }

        // Simple property access? Replace myself with a getter call.
        if(ref && ref instanceOf?(PropertyDecl)) {
            // Make sure we're not in a getter/setter yet (the trail would contain `ref` then)
            if(ref as PropertyDecl inOuterSpace(trail)) {
                // Test that we're not part of an assignment (which will be replaced by a setter call)
                // That's also the case for operators like +=, *=, /= ...
                parent := trail peek()
                shouldReplace := match parent {
                    case op: BinaryOp =>
                        // writing a property should not call its getter
                        !(op isAssign() && op left == this)
                    case =>
                        // everything that's not binary op is a property read
                        true
                }

                if(shouldReplace) {
                    property := ref as PropertyDecl
                    fCall := FunctionCall new(expr, property getGetterName(), token)
                    if (!trail peek() replace(this, fCall)) {
                        res throwError(CouldntReplace new(token, this, fCall, trail))
                    }
                    res wholeAgain(this, "Got replaced!")
                    return Response OK
                }
            } else {
                // We are in a setter/getter and we're having a variable access. That means
                // the property is not virtual.
                ref as PropertyDecl setVirtual(false)
            }
        }

        if(!_warned && trail peek() instanceOf?(Scope)) {
            parent := trail peek() as Scope

            size := parent list getSize()
            idxOf := parent list indexOf(this)
            if(idxOf != -1 && idxOf != (size - 1)) {
                res throwError(Warning new(token, "Statement with no effect"))
            }
            _warned = true
        }

        if(!ref) {
            if(res fatal) {
                subject := this
                if(reverseExpr && _staticFunc && name == "this") {
                    res throwError(InvalidAccess new(this,
                        "Can't access instance variable '%s' from static function '%s'!" \
                            format(reverseExpr prettyName, _staticFunc prettyName)
                    ))
                }

                if(res params veryVerbose) {
                    println("trail = " + trail toString())
                }
                msg := "Undefined symbol '%s'" format(subject toString())
                msg += "Trail = #{trail}"
                if (res params helpful) {
                    similar := subject findSimilar(res)
                    if(similar) {
                        msg += similar
                    }
                }
                res throwError(UnresolvedAccess new(subject, msg))
            }
            if(res params veryVerbose) {
                "     - access to %s%s still not resolved, looping (ref = %s)" printfln(\
                expr ? (expr toString() + "->")  : "", prettyName, ref ? ref toString() : "(nil)")
            }
            res wholeAgain(this, "Couldn't resolve varacc")
        }

        if (debugCondition()) {
            token printMessage("About to check generic access")
        }
        checkGenericAccess(trail, res)

        return Response OK

    }

    _genericAccessDone := false

    checkGenericAccess: func (trail: Trail, res: Resolver) {
        type := getType()
        if (!type) {
            res wholeAgain(this, "need our type")
            return
        }

        typeRef := getType() getRef()
        if (!typeRef) {
            res wholeAgain(this, "need our type's ref")
            return
        }

        parent := trail peek()
        match parent {
            case cast: Cast =>
                // parent is already an explicit cast, nothing to do
                _genericAccessDone = true
                return
        }

        if (trail isLHS(this)) {
            // we're being assigned to, no cast needed (nor wanted)
            _genericAccessDone = true
            return
        }

        if (expr == null) {
            // we can't infer our type without an expr
            _genericAccessDone = true
            return
        }

        if (debugCondition()) {
            token printMessage("About to realtypize maybe?")
        }

        if (type isGeneric()) {
            if (debugCondition()) {
                token printMessage("realtypizing!")
            }
            realTypize(trail, res)
            if (debugCondition()) {
                token printMessage("done realtypizing.")
            }
            return
        }

        // so we're not a generic type, but we still might have some
        // type args that are generic!
        typeArgs := type getTypeArgs()

        if (typeArgs == null) {
            // no type args, nothing to do
            _genericAccessDone = true
            return
        }

        hasGenericTypeArgs := false
        for (typeArg in typeArgs) {
            if (typeArg getRef() == null) {
                res wholeAgain(this, "need ref of all typeArgs of our type")
                return
            }

            if (typeArg isGeneric()) {
                hasGenericTypeArgs = true
                break
            }
        }

        if (!hasGenericTypeArgs) {
            // no generic type args, all good
            _genericAccessDone = true
            return
        }

        if (debugCondition()) {
            token printMessage("realtypizing inner!")
        }
        realTypizeInner(trail, res)
    }

    /**
     * Turn `T` into the real type, inferred from the expr, as in this
     * example:
     *
     *   Gift: class <T> {
     *     t: T
     *     init: func (=t)
     *   }
     *   g := Gift<Int> new(42)
     *   g t toString() println() // `g t` should have type `Int`, not `T`
     */
    realTypize: func (trail: Trail, res: Resolver) {
        // TODO: re-check preconditions here?
        // should only be called by checkGenericAccess

        ourTypeArg := getType() getName()
        finalScore := 0
        realType := expr getType() searchTypeArg(ourTypeArg, finalScore&)
        if (debugCondition()) {
            token printMessage("done doing searchTypeArg, finalScore = #{finalScore}")
        }

        if (finalScore == -1) {
            // try again next time!
            return
        }

        if (realType == null || realType isGeneric()) {
            if (debugCondition()) {
                token printMessage("realType null or generic :(")
            }
            // we're probably inside a generic type declaration, where generic
            // types aren't real yet
            _genericAccessDone = true
            return
        }

        if (debugCondition()) {
            token printMessage("realType for #{this} found to be #{realType}, with ref #{realType getRef()}")
        }

        cast := Cast new(this, realType clone(), token)
        if (!trail peek() replace(this, cast)) {
            res throwError(CouldntReplace new(token, this, cast, trail))
        }
        res wholeAgain(this, "Just realtypized ourselves")
        _genericAccessDone = true
        return
    }

    realTypizeInner: func (trail: Trail, res: Resolver) {
        type := getType()

        typeResult := type clone()
        exprType := expr getType()

        typeArgs := typeResult getTypeArgs()
        replacedSome := false

        for ((i, typeArg) in typeArgs) {
            finalScore := 0
            realType := expr getType() searchTypeArg(typeArg getName(), finalScore&)

            if (finalScore == -1) {
                // try again next time!
                return
            }

            if (realType == null || realType isGeneric()) {
                // we're probably inside a generic type declaration, where generic
                // types aren't real yet
                continue
            }

            typeArgs set(i, TypeAccess new(realType, typeArg token))
            replacedSome = true
        }

        if (!replacedSome) {
            // turns out there was nothing to replace! all good.
            _genericAccessDone = true
            return
        }

        cast := Cast new(this, typeResult clone(), token)
        if (!trail peek() replace(this, cast)) {
            res throwError(CouldntReplace new(token, this, cast, trail))
        }
        res wholeAgain(this, "Just inner-realtypized ourselves")
        _genericAccessDone = true
        return
    }

    findSimilar: func (res: Resolver) -> String {

        buff := Buffer new()

        for(imp in res collectAllImports()) {
            module := imp getModule()

            type := module getTypes() get(name)
            if(type) {
                buff append(" (Hint: there's such a type in "). append(imp getPath()). append(")")
            }
        }

        buff toString()

    }

    getBuiltin: func (name: String) -> Expression {
        match name {
            case "__BUILD_DATETIME__" =>
                StringLiteral new(Time dateTime(), token)
            case "__BUILD_TARGET__" =>
                StringLiteral new(Target toString(), token)
            case "__BUILD_ROCK_VERSION__" =>
                StringLiteral new(RockVersion getName(), token)
            case "__BUILD_ROCK_CODENAME__" =>
                StringLiteral new(RockVersion getCodename(), token)
            case "__BUILD_HOSTNAME__" =>
                StringLiteral new(System hostname(), token)
            case =>
                null
        }
    }

    getRef: func -> Declaration { ref }

    getType: func -> Type {
        if(!ref) {
            return null
        }

        match ref {
            case nDecl: NamespaceDecl =>
                voidType
            case expr: Expression =>
                expr getType()
            case =>
                // nothing
                null
        }
    }

    isMember: func -> Bool {
        if (!expr) {
            return false
        }

        match expr {
            case vAcc: VariableAccess =>
                if (vAcc getRef() != null && vAcc getRef() instanceOf?(NamespaceDecl)) {
                    return false
                }
        }

        true
    }

    getName: func -> String { name }

    toString: func -> String {
        expr ? (expr toString() + " " + prettyName) : prettyName
    }

    isReferencable: func -> Bool { ref && ref instanceOf?(VariableDecl) && 
    (ref as VariableDecl isExtern() && ref as VariableDecl isConst()) ? false : true }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo as Expression; true
            case => false
        }
    }

    setRef: func(=ref) {}

}

UnresolvedAccess: class extends Error {
    access: VariableAccess

    init: func (=access, .message) {
        super(access token, message)
    }
}

InvalidAccess: class extends Error {
    access: VariableAccess

    init: func (=access, .message) {
        super(access token, message)
    }
}

NeedsDeref: class extends Error {
    access: VariableAccess

    init: func (=access, .message) {
        super(access token, message)
    }
}

