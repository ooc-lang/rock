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

    _replaced := false
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

    /** Name, but with __quest and __bang turned back into '?' and '!' **/
    prettyName: String { get {
      unbangify(name)
    } }

    /** Declaration being accessed, usually a VariableDecl, could be something else. */
    ref: Declaration

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
        _funcTypeDone = false
    }

    isResolved: func -> Bool {
        if (ref == null) {
            return false
        }

        if (!_funcTypeDone) {
            return false
        }

        if (getType() == null || getType() getRef() == null) {
            return false
        }

        if (expr != null && !expr isResolved()) {
            return false
        }

        if (_replaced) {
            return false
        }

        true
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if (isResolved()) {
            return Response OK
        }

        if(debugCondition() || res params veryVerbose) {
            token printMessage("Resolving. Current ref = #{ref ? ref toString() : "<none>"} inferred type = #{getType() ? getType() toString() : "(nil)"}")
        }

        if(expr != null) {
            trail push(this)

            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                res wholeAgain(this, "Waiting on our expr to resolve...")
                return response
            }

            // don't go further until we know our expr is resolved
            if (!expr isResolved() || expr getType() == null) {
                res wholeAgain(this, "Waiting on our expr to resolve...")
                return Response OK
            }
        }

        // Mark whether we're in a static func or not for further error checking
        trail onOuter(FunctionDecl, |fDecl|
            if(fDecl isStatic()) _staticFunc = fDecl
        )

        // What do we refer to?
        match checkAccessResolution(trail, res) {
            case BranchResult BREAK => return Response OK
            case BranchResult LOOP  => return Response LOOP
        }

        // Do we need to turn into a closure struct?
        match checkFuncType(trail, res) {
            case BranchResult BREAK => return Response OK
            case BranchResult LOOP  => return Response LOOP
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
                        if (res fatal) {
                            res throwError(CouldntReplace new(token, this, fCall, trail))
                            return Response OK
                        }
                        res wholeAgain(this, "couldn't replace with getter call")
                        return Response OK
                    }
                    _replaced = true
                    res wholeAgain(this, "replaced with getter call")
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

        if (debugCondition()) {
            token printMessage("about to check generic access")
        }
        checkGenericAccess(trail, res)

        return Response OK

    }
    
    /**
     * 
     */
    checkAccessResolution: func (trail: Trail, res: Resolver) -> BranchResult {
        if (ref != null) {
            // already resolved!
            return BranchResult CONTINUE
        }

        if(expr) {
            /*
             * If our name is "class", try resolving from expr in a special way
             */
            if (name == "class") {
                exprType := expr getType()
                if(exprType == null || exprType getRef() == null) {
                    res wholeAgain(this, "waiting on expr type or expr type ref for class access")
                    return BranchResult BREAK
                }

                match (exprType getRef()) {
                    case cDecl: ClassDecl =>
                        // all good, will be handled by regular resolution

                    case =>
                        // Turn `42 class` into `IntClass`
                        name = expr getType() getName()
                        ref = expr getType() getRef()
                        expr = null
                        return BranchResult CONTINUE
                }
            }

            /*
             * Try to resolve the access from the expr, e.g. if we have
             *
             *   dog name
             *
             * We try to find the type of 'dog', then find if it has such a field, etc.
             */
            if (!expr isResolved()) {
                res wholeAgain(this, "waiting for expr to resolve..")
                return BranchResult BREAK
            }

            // Try namespace resolution first
            match expr {
                case va: VariableAccess =>
                    vaRef := va getRef()

                    match vaRef {
                        case null =>
                            res wholeAgain(this, "need va ref")
                            return BranchResult BREAK
                        case nDecl: NamespaceDecl =>
                            nDecl resolveAccess(this, res, trail)
                            if (ref != null) {
                                // all good!
                                return BranchResult CONTINUE
                            }
                    }
            }

            exprType := expr getType()
            if(exprType == null) {
                res wholeAgain(this, "expr's type isn't resolved yet, and it's needed to resolve the access")
                return BranchResult BREAK
            }

            // (we compare classes instead of using pointerLevel or instanceOf?
            // because we want accesses of an ArrayType to be legal)
            if(exprType class == PointerType) {
                msg := "Can't access field '#{prettyName}' in type '#{exprType}' without dereferencing it"
                res throwError(NeedsDeref new(this, msg))
                return BranchResult BREAK
            }

            exprRef := exprType getRef()
            if(exprRef == null) {
                if(res fatal) {
                    msg := "can't resolve type #{exprType}"
                    err := UnresolvedType new(expr token, expr getType(), msg)
                    res throwError(err)
                }
                res wholeAgain(this, "access to unresolved type decl, looping")
                return BranchResult BREAK
            }

            if (debugCondition()) {
                token printMessage("Calling resolveAccess on exprRef #{exprRef}")
            }

            result := exprRef resolveAccess(this, res, trail)
            if (result == -1) {
                res wholeAgain(this, "asked to wait by exprRef")
                return BranchResult BREAK
            }

        } else {
            /*
             * Try resolving as a builtin, e.g. __BUILD_DATE__, etc.
             */
            builtin := getBuiltin(name)
            if (builtin) {
                if(!trail peek() replace(this, builtin)) {
                    res throwError(CouldntReplace new(token, this, builtin, trail))
                }
                res wholeAgain(this, "builtin replaced")
                return BranchResult BREAK
            }

            /*
             * Try to resolve the access from the trail
             *
             * It's far simpler than resolving a function call, we just
             * explore the trail from top to bottom and retain the first match.
             */
            depth := trail getSize() - 1

            while (depth >= 0) {
                node := trail get(depth)

                match node {
                    case tDecl: TypeDecl =>
                        if (tDecl isMeta) {
                            node = tDecl getNonMeta()
                        }

                        if (name == "this") {
                            if (reverseExpr && _staticFunc) {
                                res throwError(InvalidAccess new(this,
                                    "Can't access instance variable '%s' from static function '%s'!" \
                                    format(reverseExpr prettyName, _staticFunc prettyName)
                                ))
                                return BranchResult BREAK
                            }

                            if (trail find(Scope) == -1) {
                                // in initialization of a member object!
                                // nowadays, covers have __cover_defaults__ but they have
                                // by-ref this, for obvious reasons.
                                isThisRef := trail find(CoverDecl) != -1

                                suggest(isThisRef ? tDecl thisRefDecl : tDecl thisDecl)

                                // all good!
                                return BranchResult CONTINUE
                            }
                        }

                }

                status := node resolveAccess(this, res, trail)
                if (status == -1) {
                    res wholeAgain(this, "asked to wait while resolving access")
                    return BranchResult BREAK
                }

                if (ref != null) {
                    if (expr == null) {
                        // potentially capture vDecl
                        match ref {
                            case vDecl: VariableDecl =>
                                if (!vDecl isGlobal()) {
                                    // only accesses to variable decls need to be captured (not type decls)
                                    vDecl captureInUpstreamClosures(trail, depth, this)
                                }
                        }
                    } else {
                        // resolving the call gave us an expr (e.g. we were accessing
                        // an unqualified member field), which we need to resolve
                        trail push(this)
                        response := expr resolve(trail, res)
                        trail pop(this)
                        if (!response ok()) {
                            res wholeAgain(this, "waiting on expr")
                            return BranchResult BREAK
                        }
                    }

                    break // break on first match
                }

                depth -= 1
            }
        }

        if (ref == null) {
            if (res fatal) {
                msg := "Undefined symbol '#{this}'"
                if (res params helpful) {
                    similar := findSimilar(res)
                    if(similar) {
                        msg += similar
                    }
                }
                res throwError(UnresolvedAccess new(this, msg))
            }
            res wholeAgain(this, "waiting to find out ref of variable access")
            BranchResult BREAK
        } else {
            BranchResult CONTINUE
        }
    }

    _funcTypeDone := false

    /**
     * Check if we need to turn into a closure struct literal (containing thunk + context)
     */
    checkFuncType: func (trail: Trail, res: Resolver) -> BranchResult {
        if (_funcTypeDone) {
            return BranchResult CONTINUE
        }

        if (!getType() instanceOf?(FuncType)) {
            _funcTypeDone = true
            return BranchResult CONTINUE
        }

        ourType := getType() as FuncType
        parent := trail peek()

        if (ourType isClosure) {
            // already a closure
            _funcTypeDone = true
            return BranchResult CONTINUE
        }

        inferredType: Type

        if (debugCondition() || res params veryVerbose) {
            token printMessage("[checkFuncType] checking #{this}. parent = #{parent}")
        }

        match (parent typeForExpr(trail, this, inferredType&)) {
            case SearchResult RETRY =>
                res wholeAgain(this, "waiting on parent to infer our type")
                return BranchResult BREAK

            case SearchResult NONE =>
                // no conversion needed, all done
                _funcTypeDone = true
                return BranchResult CONTINUE
        }

        if (!inferredType instanceOf?(FuncType)) {
            // Not a func type, no need to convert
            // TODO: check for reverse conversions & disallow
            _funcTypeDone = true
            return BranchResult CONTINUE
        }

        ourType isClosure = true

        closureElements := ArrayList<Expression> new().
            add(this).
            add(NullLiteral new(token))

        closure := StructLiteral new(inferredType, closureElements, token)

        if(!parent replace(this, closure)) {
            res throwError(CouldntReplace new(token, this, closure, trail))
        }

        if (debugCondition() || res params veryVerbose) {
            token printMessage("[funcTypeDone] replaced #{this} with closure #{closure}")
        }
        _funcTypeDone = true
        BranchResult CONTINUE
    }

    _genericAccessDone := false

    /**
     * Check if we're accessible a variable of generic type,
     * in which case we need to be cast.
     */
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

        if (trail lvalue?(this)) {
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

        exprType := expr getType()
        if (exprType == null || exprType getRef() == null) {
            res wholeAgain(this, "need expr type to realtypize")
            return
        }

        realType := exprType searchTypeArg(ourTypeArg, finalScore&)
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
        if (exprType == null || exprType getRef() == null) {
            res wholeAgain(this, "waiting for expr type")
            return
        }

        typeArgs := typeResult getTypeArgs()
        replacedSome := false

        for ((i, typeArg) in typeArgs) {
            finalScore := 0
            realType := exprType searchTypeArg(typeArg getName(), finalScore&)

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

    /**
     * A list of global variables that are evaluated at compile time
     * cf. https://ooc-lang.org/docs/lang/preprocessor/#constants
     */
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

