import structs/[ArrayList, List, HashMap]
import io/File
import ../frontend/[Token, BuildParams, CommandLine]
import Visitor, Expression, FunctionDecl, Argument, Type,
       TypeDecl, Node, VariableDecl, VariableAccess, AddressOf, CommaSequence, BinaryOp,
       InterfaceDecl, Cast, NamespaceDecl, BaseType, FuncType, Return,
       TypeList, Scope, Block, StructLiteral, NullLiteral,
       IntLiteral, Ternary, ClassDecl, CoverDecl, ArrayLiteral, Module,
       StringLiteral
import algo/typeAnalysis
import text/EscapeSequence
import tinker/[Response, Resolver, Trail, Errors]

/**
 * Every function call, member or not, is represented by this AST node.
 *
 * Member calls (ie. "blah" println()) have a non-null 'expr'
 *
 * Calls to functions with generic type arguments store the 'resolution'
 * of these type arguments in the typeArgs list. Until all type arguments
 * are resolved, the function call is not fully resolved.
 *
 * Calls to functions that have multi-returns or a generic return type
 * use returnArgs expression (secret variables that are references,
 * and are assigned to when the return happens.)
 */

IMPLICIT_AS_EXTERNAL_ONLY: const Bool = true

FunctionCall: class extends Expression {
    /**
     * Arguments passed to VarArgs, if those exist
     */
    varArgs: ArrayList<Expression>

    /**
     * VarArg arguments structure name, if any
     */
    vaStruct: String = null

    /**
     * Expression on which we call something, if any. Function calls
     * have a null expr, method calls have a non-null ones.
     */
    expr: Expression

    /** Name of the function being called. */
    name: String

    prettyName: String { get {
      unbangify(name)
    } }

    /**
     * If the suffix is non-null (ie it has been specified in the code,
     * via name~suffix()), it won't accept functions that have a different
     * suffix.
     *
     * If suffix is null, it'll just try to find the best match, no matter
     * the suffix.
     */
    suffix = null : String

    /**
     * Resolved declaration's type arguments. For example,
     * ArrayList<Int> new() will have 'Int' in its typeArgs.
     */
    typeArgs := ArrayList<Expression> new()

    /**
     * Calls to functions that have multi-returns or a generic return type
     * use returnArgs expression (secret variables that are references,
     * and are assigned to when the return happens.)
     */
    returnArgs := ArrayList<Expression> new()

    /**
     * Inferred return type of the call - might be different from ref's returnType
     * if it is generic, for example.
     */
    returnType : Type = null

    args := ArrayList<Expression> new()

    /**
     * The actual function declaration this call is calling.
     * Note that this makes rock almost a linker too - it effectively
     * knows the ins and outs of all your calls before it dares
     * generate C code.
     */
    ref = null : FunctionDecl

    /**
     * By default member method calls are virtual calls, ie. they call
     * the implementation of the *actual*, concrete class of the object it's called
     * on, not on the abstract class we might be calling it on.
     *
     * This is only used internally when we really want to call the _impl variant
     * instead.
     */
    virtual := true

    /**
     * < 0 = not resolved (incompatible functions)
     * > 0 = resolved
     *
     * Score is determined in getScore(), depending on the arguments, etc.
     *
     * Function declarations that don't even match the name don't even
     * have a score.
     */
    refScore := INT_MIN

    /**
     * When 'implicit as' is used, args are modified, and this map
     * keeps track of what has been modified, to be able to restore it.
     */
    argsBeforeConversion: HashMap<Int, Expression>
    candidateUsesAs := false

    /**
     * Set to true when we've finished the resolving process:
     */
    resolved := false

    /**
     * Create a new function call to the function '<name>()'
     */
    init: func ~funcCall (=name, .token) {
        super(token)
    }

    /**
     * Create a new method (member function) call to the function 'expr <name>()'
     */
    init: func ~functionCallWithExpr (=expr, =name, .token) {
        super(token)
    }

    clone: func -> This {
        copy := new(expr ? expr clone() : expr, name, token)
        copy suffix = suffix
        args each(|arg|
            copy args add(arg clone())
        )
        copy
    }

    setExpr: func (=expr) {}
    getExpr: func -> Expression { expr }

    setName: func (=name) {}
    getName: func -> String { name }

    setSuffix: func (=suffix) {}
    getSuffix: func -> String { suffix }

    accept: func (visitor: Visitor) {
        visitor visitFunctionCall(this)
    }

    /**
     * Internal method used to print a shitload of debugging messages
     * on a particular function - used in one-shots of hardcore debugging.
     *
     * Usually has 'name == "something"' instead of 'false' as
     * a return expression, when it's being used.
     */
    debugCondition: final func -> Bool {
        false
    }

    /**
     * This method is being called by other AST nodes that want to suggest
     * a function declaration to this function call.
     *
     * The call then evaluates the score of the decl, and if it has a higher score,
     * stores it as its new best ref.
     */
    suggest: func (candidate: FunctionDecl, res: Resolver, trail: Trail) -> Bool {

        if(debugCondition()) "** [refScore = %d, ref = %s] Got suggestion %s for %s" printfln(refScore, ref ? ref toString() : "(nil)", candidate toString(), toString())

        if(isMember() && candidate owner == null) {
            if(debugCondition()) "** %s is no fit!, we need something to fit %s" printfln(candidate toString(), toString())
            return false
        }

        score := getScore(candidate)
        if (score <= refScore) {
            // usually we'd give up here, except..
            if (refScore == -1 && ref == candidate) {
                // then we'll continue
            } else {
                // we can give up.
                return false
            }
        }

        if(debugCondition()) {
            "** New high score, %d/%s wins against %d/%s" format(score, candidate toString(), refScore, ref ? ref toString() : "(nil)") println()
        }
        refScore = score
        ref = candidate

        if(score == -1) {
            if(debugCondition()) "** Score = -1! Aboort" println()
            if(res fatal) {
                // check our arguments are all right
                checkArgumentValidity(res)
            }
            return false
        }

        // todo: optimize that. not all of this needs to happen in many cases
        if(argsBeforeConversion) {
            for(i in argsBeforeConversion getKeys()) {
                callArg := argsBeforeConversion[i]
                args set(i, callArg)
            }
        }
        candidateUsesAs = false

        for(i in 0..args getSize()) {
            if(i >= candidate args getSize()) break
            declArg := candidate args get(i)
            if(declArg instanceOf?(VarArg)) break
            callArg := args get(i)

            if(callArg getType() == null) return false
            if(declArg getType() == null) return false
            declArgType := declArg getType() refToPointer()
            if (declArgType isGeneric()) {
                declArgType = declArgType realTypize(this)
            }

            if(callArg getType() getScore(declArgType) == Type NOLUCK_SCORE) {
                ref := callArg getType() getRef()
                if(ref instanceOf?(TypeDecl)) {
                    ref as TypeDecl implicitConversions each(|opdecl|
                        if(opdecl fDecl getReturnType() equals?(declArgType)) {
                            candidateUsesAs = true
                            if(!(IMPLICIT_AS_EXTERNAL_ONLY) || candidate isExtern()) {
                                args set(i, Cast new(callArg, declArgType, callArg token))
                                if(!argsBeforeConversion) {
                                    // lazy instantiation of argsBeforeConversion
                                    argsBeforeConversion = HashMap<Int, Expression> new()
                                }
                                argsBeforeConversion put(i, callArg)
                            }
                        }
                    )
                }
            }
        }
        return score > 0

    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if (name == "slurp" && expr == null) {
            mod := trail module()

            if (args size < 1) {
                message := "slurp needs one argument: the file to slurp"
                res throwError(InvalidSlurp new(this, message, ""))
            }
            arg := args get(0)
            match (arg) {
                case sl: StringLiteral =>
                    path := sl value
                    file := File new(mod pathElement, path)
                    if (!file exists?()) {
                        message := "while slurping, file not found: #{file getReducedPath()}"
                        res throwError(InvalidSlurp new(this, message, ""))
                    }

                    contents := file read()
                    escaped := EscapeSequence escape(contents)
                    kid := StringLiteral new(escaped, token)
                    if (!trail peek() replace(this, kid)) {
                        res throwError(CouldntReplace new(token, this, kid, trail))
                    }
                    res wholeAgain(this, "just unwrapped")
                    return Response OK

                case =>
                    message := "slurp only accepts paths via string literal"
                    res throwError(InvalidSlurp new(this, message, ""))
            }
        }

        if(debugCondition() || res params veryVerbose) {
            "===============================================================" println()
            "     - Resolving call to %s (ref = %s, refScore = %d)" printfln(name, ref ? ref toString(): "(nil)", refScore)
        }

        // resolve all arguments
        unresolvedArgs := false
        if(!args empty?()) {
            trail push(this)
            i := 0

            resolveArg := func(arg: Expression, replaced?: Bool) -> Response {
                if(debugCondition() || res params veryVerbose) {
                    "resolving%s arg %s" printfln(replaced? ? " replaced" : "", arg toString())
                }
                response := arg resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    return response
                }
                if(!replaced?) i += 1
                if(!arg isResolved()) {
                    if (debugCondition() || res params veryVerbose) {
                        "for call %s, arg still not resolved: %s" printfln(toString(), arg toString())
                    }
                    unresolvedArgs = true
                }

                return Response OK
            }

            for(arg in args) {
                response := resolveArg(arg, false)
                if(!response ok()) return response
            }

            // resolve the arguments we replaced with the varArg structure access
            if(varArgs) {
                for(arg in varArgs) {
                    response := resolveArg(arg, true)
                    if(!response ok()) {
                        return response
                    }
                }
            }

            trail pop(this)
        }

        // resolve our expr. e.g. in
        //     object doThing()
        // object is our expr.
        if (expr) {
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                if(res params veryVerbose) "Failed to resolve expr %s of call %s, looping" printfln(expr toString(), toString())
                return response
            }

            if (!expr isResolved()) {
                res wholeAgain(this, "waiting on expr to resolve...")
                return Response OK
            }
        }

        // resolve all returnArgs (secret arguments used when we have
        // multi-return and/or generic return type
        for(i in 0..returnArgs getSize()) {
            returnArg := returnArgs[i]
            if(!returnArg) continue // they can be null, after all.

            response := returnArg resolve(trail, res)
            if(!response ok()) return response

            if(returnArg isResolved() && !returnArg instanceOf?(AddressOf)) {
                returnArgs[i] = returnArg getGenericOperand()
            }
        }

        /*
         * Try to resolve the call.
         *
         * We don't only have to find one definition, we have to find
         * the *best* one. For that, we're sticking to our fun score
         * system. A call can determine the score of a decl, based
         * mostly on the types of the arguments, the suffix, etc.
         *
         * Since we're looking for the best, we have to do the whole
         * trail from top to bottom
         */
        if(refScore <= 0) {
            if(debugCondition()) "\n===============\nResolving call %s" printfln(toString())

            if (expr != null && name == "instanceOf__quest") {
                exprType := expr getType()
                if (exprType == null) {
                    res wholeAgain(this, "waiting for expr type")
                    return Response OK
                }
                ref := exprType getRef()
                if (ref == null) {
                    res wholeAgain(this, "waiting for expr type ref")
                    return Response OK
                }
                match ref {
                    case cd: CoverDecl =>
                        "got a call to #{toString()}, expr type ref = #{ref toString()}" println()
                        expr = VariableAccess new(expr, "class", expr token)
                        name = "inheritsFrom__quest"
                        res wholeAgain(this, "replaced instanceOf with inheritsFrom")
                        return Response OK
                }
            }

            if (res fatal && refScore == -1) {
                // something went wrong somewhere else
                res wholeAgain(this, "call #{this} waiting on #{ref ? ref toString() : "a function"} to resolve.")
                return Response OK
            }

            if(name == "super") {
                fDecl := trail get(trail find(FunctionDecl), FunctionDecl)
                superTypeDecl := fDecl owner getSuperRef()
                finalScore := 0
                ref = superTypeDecl getMeta() getFunction(fDecl getName(), null, this, finalScore&)
                if(finalScore == -1) {
                    res wholeAgain(this, "something in our typedecl's functions needs resolving!")
                    return Response OK
                }
                if(ref != null) {
                    refScore = 1
                    expr = VariableAccess new(superTypeDecl getThisDecl(), token)
                    if(args empty?() && !ref getArguments() empty?()) {
                        for(declArg in fDecl getArguments()) {
                            args add(VariableAccess new(declArg, token))
                        }
                    }
                }
            } else {
                if(expr == null) {
                    depth := trail getSize() - 1
                    while(depth >= 0) {
                        node := trail get(depth, Node)
                        if(node resolveCall(this, res, trail) == -1) {
                            res wholeAgain(this, "Waiting on other nodes to resolve before resolving call.")
                            return Response OK
                        }

                        if(ref && ref vDecl) {
                            ref vDecl captureInUpstreamClosures(trail, depth)
                        }
                        depth -= 1
                    }
                } else if(expr instanceOf?(VariableAccess) && expr as VariableAccess getRef() != null && expr as VariableAccess getRef() instanceOf?(NamespaceDecl)) {
                    expr as VariableAccess getRef() resolveCall(this, res, trail)
                } else if(expr getType() != null && expr getType() getRef() != null) {
                    if(!expr getType() getRef() instanceOf?(TypeDecl)) {
                        message := "No such function %s%s for `%s`" format(prettyName, getArgsTypesRepr(), expr getType() getName())
                        precisions := ""

                        if(expr getType() isGeneric()) {
                            message += " (you can't call methods on generic types! you have to cast them first)"
                        } else if (ref) {
                            precisions += showNearestMatch(res params)
                        }
                        err := UnresolvedCall new(this, message)
                        if (!precisions empty?()) {
                            err next = InfoError new(ref ? ref token : nullToken, precisions)
                        }
                        res throwError(err)
                    }
                    tDecl := expr getType() getRef() as TypeDecl
                    meta := tDecl getMeta()
                    if(debugCondition()) "Got tDecl %s, resolving, meta = %s" printfln(tDecl toString(), meta == null ? "(nil)": meta toString())
                    if(meta) {
                        meta resolveCall(this, res, trail)
                    } else {
                        tDecl resolveCall(this, res, trail)
                    }

                    // Last resort - If we haven't found our call and we do have a meta, try to resolve it in the non-meta anyway
                    if(!ref && meta) {
                        tDecl resolveCall(this, res, trail)
                    }
                }
            }

            // args will need re-resolving after function resolution, such as: wrapping things into closures
            unresolvedArgs = true
        }

        /*
         * Now resolve return type, generic type arguments, and interfaces
         */
        if(refScore > 0) {

            if(!resolveReturnType(trail, res) ok()) {
                res wholeAgain(this, "looping because of return type!")
                return Response OK
            }

            if(!handleGenerics(trail, res) ok()) {
                res wholeAgain(this, "looping because of generics!")
                return Response OK
            }

            if(!handleOptargs(trail, res) ok()) {
                res wholeAgain(this, "looping because of optargs!")
                return Response OK
            }

            if(!handleVarargs(trail, res) ok()) {
                res wholeAgain(this, "looping because of varargs!")
                return Response OK
            }

            if(!handleInterfaces(trail, res) ok()) {
                res wholeAgain(this, "looping because of interfaces!")
                return Response OK
            }

            if(typeArgs getSize() > 0) {
                trail push(this)
                for(typeArg in typeArgs) {
                    response := typeArg resolve(trail, res)
                    if(!response ok()) {
                        trail pop(this)
                        res wholeAgain(this, "typeArg failed to resolve\n")
                        return Response OK
                    }
                }
                trail pop(this)
            }

            unwrapIfNeeded(trail, res)

            if(returnType) {
                if (debugCondition()) {
                    "returnType for %s is %s, re-resolving it just to make sure" printfln(toString(), returnType toString())
                }
                response := returnType resolve(trail, res)
                if(!response ok()) return response

                if(returnType void?) {
                    parent := trail peek()
                    if(!parent instanceOf?(Scope) && !parent instanceOf?(CommaSequence)) {
                        res throwError(UseOfVoidExpression new(token, "Use of a void function call `#{this}` as an expression"))
                    }
                }
            }

        }

        if(refScore <= 0) {

            precisions := ""

            // Still no match, and in the fatal round? Throw an error.
            if(res fatal || (refScore < -1 && refScore > INT_MIN)) {
                if (refScore == -1) {
                    // something went wrong somewhere else
                    res wholeAgain(this, "(in refScore <= 0) waiting on some FunctionDecl to resolve.")
                    return Response OK
                }

                message := "No such function"
                if(expr == null) {
                    message = "No such function %s%s" format(prettyName, getArgsTypesRepr())
                } else if (expr getType() != null) {
                    if(res params veryVerbose) {
                        message = "No such function %s%s for `%s` (%s)" format(prettyName, getArgsTypesRepr(),
                            expr getType() toString(), expr getType() getRef() ? expr getType() getRef() token toString() : "(nil)")
                    } else {
                        message = "No such function %s%s for `%s`" format(prettyName, getArgsTypesRepr(), expr getType() toString())
                    }
                }

                if(ref) {
                    // If we have a near-match, show it here.
                    precisions += showNearestMatch(res params)
                    // TODO: add levenshtein distance

                    if (ref && candidateUsesAs) {
                        precisions += "\n\n(Hint: 'implicit as' isn't allowed on non-extern functions)"
                    }
                } else {
                    if(res params helpful) {
                        // Try to find such a function in other modules in the sourcepath
                        similar := findSimilar(res)
                        if(similar) message += similar
                    }
                }
                err := UnresolvedCall new(this, message)
                if (!precisions empty?()) {
                    err next = InfoError new(ref ? ref token : nullToken, precisions)
                }
                res throwError(err)
                return Response OK
            } else {
                res wholeAgain(this, "no match yet")
                return Response OK
            }

        }

        // finally, avoid & on lvalues: unwrap unreferencable expressions.
        if(ref && ref isThisRef && expr && !expr isReferencable()) {
            vDecl := VariableDecl new(null, generateTempName("unwrapped_lvalue"), expr, expr token)
            trail addBeforeInScope(this, vDecl)
            expr = VariableAccess new(vDecl, expr token)
            return Response OK
        }

        // check we are not trying to call a non-static member function on the metaclass
        if(expr instanceOf?(VariableAccess) && \
        (expr as VariableAccess getRef() instanceOf?(ClassDecl) || expr as VariableAccess getRef() instanceOf?(CoverDecl)) && \
        (expr as VariableAccess getRef() as TypeDecl inheritsFrom?(ref getOwner()) || \
        expr as VariableAccess getRef() == ref getOwner()) && !ref isStatic) {
            msg := "No such function %s%s for `%s` (%s)" format(prettyName, getArgsTypesRepr(),
                            expr getType() toString(), expr getType() getRef() ? expr getType() getRef() token toString() : "(nil)")
            res throwError(UnresolvedCall new(this, msg))
        }

        /* 
         * Check for String instances passed to C vararg functions if helpful.
         * Skip `va_arg`. `va_arg` is a vararg function that takes the
         * last-before-vararg argument as an argument. For methods, it's always
         * `this` (implicit first argument).  So, skip it.
         */
        if(res params helpful && this name != "va_start") {
            doIt := true
            idx := 0
            for(arg in ref args) {
                if(!doIt)
                    break
                if(arg instanceOf?(VarArg)) {
                    varIdx := idx
                    // Yes, Virginia, there are varargs.
                    pi := 0
                    for(passedArg in this args) {
                        if(passedArg getType() && passedArg getType() getName() == "String" && pi >= varIdx) {
                            passedArg token formatMessage("Passing String to C vararg function.", "HINT") println()
                        }
                        doIt = false
                        pi += 1
                    }
                }
                idx += 1
            }
        }

        if (unresolvedArgs) {
            res wholeAgain(this, "waiting for all args to resolve")
            return Response OK
        }

        if (expr && !expr isResolved()) {
            res wholeAgain(this, "waiting on expr to resolve")
            return Response OK
        }

        /*
         * Setting it too soon would cause some important stuff to never
         * happen, such as wrapping function pointers into closures. Too late
         * would make rock blow up. I'm not happy with that (amos)
         */
        resolved = true

        return Response OK
    }

    findSimilar: func (res: Resolver) -> String {
        buff := Buffer new()

        for(imp in res collectAllImports()) {
            module := imp getModule()

            fDecl := module getFunctions() get(name)
            if(fDecl) {
                buff append(" (Hint: there's such a function in "). append(imp getPath()). append(")")
            }
        }

        buff toString()
    }

    /**
     * If we have a ref but with a negative score, it means there's a function
     * with the right name, but that doesn't match in respect with the arguments
     */
    showNearestMatch: func (params: BuildParams) -> String {
        b := Buffer new()

        b append("Nearest match is `#{ref toString(this)}`")

        callIter := args iterator()
        declIter := ref args iterator()

        while(callIter hasNext?() && declIter hasNext?()) {
            declArg := declIter next()
            if(declArg instanceOf?(VarArg)) break
            callArg := callIter next()

            if(declArg getType() == null) {
                b append("\n..but couldn't resolve type of argument `#{declArg}` in the declaration")
                continue
            }

            if(callArg getType() == null) {
                b append("\n..but couldn't resolve type of argument `#{callArg}` in the call")
                continue
            }

            declArgType := declArg getType()
            if(declArgType isGeneric()) {
                declArgType = declArgType realTypize(this)
            }

            score := callArg getType() getScore(declArgType)
            if(score < 0) {
                if(params veryVerbose) {
                    b append("\n..but the type of this arg should be `%s` (%s), not %s (%s)\n" format(declArgType toString(), declArgType getRef() ? declArgType getRef() token toString() : "(nil)",
                                                                                           callArg getType() toString(), callArg getType() getRef() ? callArg getType() getRef() token toString() : "(nil)"))
                } else {
                    b append("\n..but the arg `%s` should be of type `%s` instead of `%s`\n" format(callArg toString(), declArgType toString(), callArg getType() toString()))
                }
            }
        }

        b toString()
    }

    unwrapIfNeeded: func (trail: Trail, res: Resolver) -> Response {

        parent := trail peek()

        if(ref == null || ref returnType == null) {
            res wholeAgain(this, "need ref and refType")
            return Response OK
        }

        idx := 2
        while(parent instanceOf?(Cast)) {
            parent = trail peek(idx)
            idx += 1
        }

        if(!ref getReturnArgs() empty?() && ref getReturnType() isGeneric() && !isFriendlyHost(parent)) {
            if(parent instanceOf?(Return)) {
                fDeclIdx := trail find(FunctionDecl)
                if(fDeclIdx != -1) {
                    fDecl := trail get(fDeclIdx) as FunctionDecl
                    retType := fDecl getReturnType()
                    if(!retType isResolved()) {
                        res wholeAgain(this, "Need fDecl returnType to be resolved")
                        return Response OK
                    }
                    if(retType isGeneric()) {
                        // will be handled by Return resolve()
                        return Response OK
                    }
                }
            }

            vType := getType() instanceOf?(TypeList) ? getType() as TypeList types get(0) : getType()
            vDecl := VariableDecl new(vType, generateTempName("genCall"), token)
            if(!trail addBeforeInScope(this, vDecl)) {
                if(res fatal) res throwError(CouldntAddBeforeInScope new(token, vDecl, this, trail))
                res wholeAgain(this, "couldn't add before scope")
                return Response OK
            }

            seq := CommaSequence new(token)
            seq origin = this
            if(!trail peek() replace(this, seq)) {
                if(res fatal) res throwError(CouldntReplace new(token, this, seq, trail))
                // FIXME: what if we already added the vDecl?
                res wholeAgain(this, "couldn't unwrap")
                return Response OK
            }

            // only modify ourselves if we could do the other modifications
            varAcc := VariableAccess new(vDecl, token)
            returnArgs add(varAcc)

            seq getBody() add(this)
            seq getBody() add(varAcc)

            res wholeAgain(this, "just unwrapped")
        }

        return Response OK

    }

    /**
     * In some cases, a generic function call needs to be unwrapped,
     * e.g. when it's used as an expression in another call, etc.
     * However, some nodes are 'friendly' parents to us, e.g.
     * they handle things themselves and we don't need to unwrap.
     * @return true if the node is friendly, false if it is not and we
     * need to unwrap
     */
    isFriendlyHost: func (node: Node) -> Bool {
        // all scopes are friendly
        if (node isScope()) return true

        match node {
            case cs: CommaSequence =>
                // that's what we use to unwrap, so, yes
                return true
            case vd: VariableDecl =>
                // friendly too, we'll know where to store the result
                return true
            case bop: BinaryOp =>
                // friendly if we're the rhs in an assignment (wrapped in a cast while not)
                if (bop type != OpType ass) {
                    return false
                }
                
                rhs := bop right
                while (rhs instanceOf?(Cast)) {
                    rhs = rhs as Cast inner
                }
                return rhs == this
        }

        false
    }

    /**
     * Attempt to resolve the *actual* return type of the call, as oppposed
     * to the declared return type of our reference (a function decl).
     *
     * Mostly useful when the return type is generic and needs to be resolved
     * to a more concrete type.
     */
    resolveReturnType: func (trail: Trail, res: Resolver) -> Response {

        if (returnType != null) return Response OK

        if (refScore < 0) {
            res wholeAgain(this, "can't resolve return type until call is fully resolved")
            return Response OK
        }

        if (res params veryVerbose) {
          "Resolving returnType of %s (=%s), returnType of ref = %s, isGeneric() = %s, ref of returnType of ref = %s, ref returnType isResolved? = %s" printfln(
            toString(), returnType ? returnType toString() : "(nil)",
            ref returnType toString(), ref returnType isGeneric() toString(),
            ref returnType getRef() ? ref returnType getRef() toString() : "(nil)",
            ref returnType isResolved() toString())
        }

        if(returnType == null && ref != null) {
            if(!ref returnType isResolved()) {
                res wholeAgain(this, "need resolve the return type of our ref to see if it's generic")
                return Response OK
            }

            finalScore := 0
            if(ref returnType isGeneric()) {
                if(res params veryVerbose) "\t$$$$ resolving returnType %s for %s" printfln(ref returnType toString(), toString())
                returnType = resolveTypeArg(trail, res, ref returnType getName(), finalScore&)

                if((finalScore == -1 || returnType == null) && res fatal) {
                    res throwError(InternalError new(token, "Not enough info to resolve return type %s of function call\n" format(ref returnType toString())))
                }
            } else {
                if (debugCondition()) {
                    "ref returnType is not generic, cloning and resolving the clone" println()
                }
                returnType = ref returnType clone()
                returnType resolve(trail, res)
            }

            if (returnType != null) {
                if (debugCondition()) {
                    token printMessage("before realtypizing, returnType = #{returnType}")
                }

                if(!realTypize(returnType, trail, res)) {
                    res wholeAgain(this, "because couldn't properly realTypize return type.")
                    returnType = null
                }

                if (debugCondition()) {
                    token printMessage("after realtypizing, returnType = #{returnType}")
                }
            }

            if(returnType) {
                if(debugCondition()) {
                    "Determined return type of %s (whose ref rt is %s) to be %s" printfln(toString(), ref getReturnType() toString(), returnType toString())
                    if(expr) "expr = %s, type = %s" printfln(expr toString(), expr getType() ? expr getType() toString() : "(nil)")
                }

                if (!res fatal) {
                    res wholeAgain(this, "returnType has just been determined, might need more rounds.")
                    return Response OK
                }
            }
        }

        if(returnType == null) {
            if(res fatal) res throwError(InternalError new(token, "Couldn't resolve return type of function %s\n" format(toString())))
            return Response LOOP
        }

        if (debugCondition()) {
            "At the end of resolveReturnType(), the return type of %s is %s" printfln(toString(), getType() ? getType() toString() : "(nil)")
        }
        return Response OK

    }

    realTypize: func (type: Type, trail: Trail, res: Resolver) -> Bool {

        if(debugCondition()) "[realTypize] realTypizing type %s in %s" printfln(type toString(), toString())

        if(type instanceOf?(BaseType) && type as BaseType typeArgs != null) {
            baseType := type as BaseType
            j := 0
            for(typeArg in baseType typeArgs) {
                if(debugCondition())  "[realTypize] for typeArg %s (ref = %s)" printfln(typeArg toString(), typeArg getRef() ? typeArg getRef() toString() : "(nil)")
                if(typeArg getRef() == null) {
                    return false // must resolve it before
                }
                if(debugCondition())  "[realTypize] Ref of typeArg %s is a %s (and expr is a %s)" printfln(typeArg toString(), typeArg getRef() class name, expr ? expr toString() : "(nil)")

                // if it's generic-unspecific, it needs to be resolved
                if(typeArg getRef() instanceOf?(VariableDecl)) {
                    typeArgName := typeArg getRef() as VariableDecl getName()
                    finalScore := 0
                    result := resolveTypeArg(trail, res, typeArgName, finalScore&)
                    if(finalScore == -1) return false
                    if(debugCondition()) "[realTypize] result = %s\n" printfln(result ? result toString() : "(nil)")
                    if(result) baseType typeArgs set(j, TypeAccess new(result, typeArg token))
                }
                j += 1
            }
        }

        return true

    }

    /**
     * Add casts for interfaces arguments
     */
    handleInterfaces: func (trail: Trail, res: Resolver) -> Response {

        i := 0
        for(declArg in ref args) {
            if(declArg instanceOf?(VarArg)) break
            if(i >= args getSize()) break
            callArg := args get(i)
            if(declArg getType() == null || declArg getType() getRef() == null ||
               callArg getType() == null || callArg getType() getRef() == null) {
                res wholeAgain(this, "To resolve interface-args, need to resolve declArg and callArg")
                return Response OK
            }
            if(declArg getType() getRef() instanceOf?(InterfaceDecl)) {
                if(!declArg getType() equals?(callArg getType())) {
                    args set(i, Cast new(callArg, declArg getType(), callArg token))
                }

            }
            i += 1
        }

        return Response OK

    }

    /**
     * Resolve optional arguments, ie. fill in default values
     */
    handleOptargs: func (trail: Trail, res: Resolver) -> Response {
        if(ref args size <= args size) return Response OK

        for(i in args size..ref args size) {
            refArg := ref args[i]
            // use the default value as an argument expression.
            if(refArg expr) args add(refArg expr)
        }

        Response OK
    }

    /**
     * Resolve ooc variable arguments
     */
    handleVarargs: func (trail: Trail, res: Resolver) -> Response {

        if(ref args empty?()) return Response OK

        match (lastArg := ref args last()) {
            case vararg: VarArg =>
                if(vararg name != null) {
                    // ooc varargs have names!
                    numVarArgs := (args size - (ref args size - 1))

                    if(!args empty?()) {
                        lastType := args last() getType()
                        if(!lastType) return Response LOOP
                        if(lastType getName() == "VarArgs") {
                            return Response OK
                        }
                    }

                    ast := AnonymousStructType new(token)
                    elements := ArrayList<Expression> new()
                    for(i in (ref args size - 1)..(args size)) {
                        arg := args[i]
                        argType := arg getType()
                        if(!argType) return Response LOOP

                        if(argType pointerLevel() > 0) {
                            argType = NullLiteral type // 'T*' = 'Pointer', != 'T'
                        }
                        elements add(TypeAccess new(argType, token))
                        ast types add(NullLiteral type)

                        elements add(arg)
                        ast types add(arg getType())
                    }
                    varArgs = elements

                    argsDecl := VariableDecl new(ast, generateTempName("__va_args"),token)
                    vaStruct = argsDecl getFullName()

                    if(!trail addBeforeInScope(this, argsDecl)) {
                        res throwError(CouldntAddBeforeInScope new(token, this, argsDecl, trail))
                    }

                    vaType := BaseType new("VarArgs", token)
                    argsAddress := AddressOf new(VariableAccess new(argsDecl, token), token)
                    elements2 := [
                        argsAddress
                        NullLiteral new(token)
                        IntLiteral new(numVarArgs, token)
                    ] as ArrayList<Expression>

                    varargsSl := StructLiteral new(vaType, elements2, token)
                    vaDecl := VariableDecl new(null, generateTempName("__va"), varargsSl, token)
                    if(!trail addBeforeInScope(this, vaDecl)) {
                        res throwError(CouldntAddBeforeInScope new(token, this, vaDecl, trail))
                    }

                    numVarArgs times(||
                        args removeAt(args lastIndex())
                    )
                    args add(VariableAccess new(vaDecl, token))
                }
        }

        Response OK

    }

    /**
     * Resolve type arguments
     */
    handleGenerics: func (trail: Trail, res: Resolver) -> Response {

        j := 0
        for(implArg in ref args) {
            if(implArg instanceOf?(VarArg)) { j += 1; continue }
            implType := implArg getType()

            if(implType == null || !implType isResolved()) {
                res wholeAgain(this, "need impl arg type"); break // we'll do it later
            }
            if(!implType isGeneric() || implType pointerLevel() > 0) { j += 1; continue }

            //" >> Reviewing arg %s in call %s, in ref %s" printfln(implArg toString(), toString(), ref toString())

            callArg := args get(j)
            typeResult := callArg getType()
            if(typeResult == null) {
                res wholeAgain(this, "null callArg, need to resolve it first.")
                return Response OK
            }

            isGood := ((callArg instanceOf?(AddressOf) && callArg as AddressOf isForGenerics) || typeResult isGeneric())
            if(!isGood) { // FIXME this is probably wrong - what if we want an address's address? etc.
                target : Expression = callArg
                if(!callArg isReferencable()) {
                    varDecl := VariableDecl new(typeResult, generateTempName("genArg"), callArg, nullToken)
                    if(!trail addBeforeInScope(this, varDecl)) {
                        "Couldn't add %s before %s, parent is a %s\n" printfln(varDecl toString(), toString(), trail peek() toString())
                    }
                    target = VariableAccess new(varDecl, callArg token)
                }
                addrOf := AddressOf new(target, target token)
                addrOf isForGenerics = true
                args set(j, addrOf)
            }
            j += 1
        }

        if(typeArgs getSize() == ref typeArgs getSize()) {
            return Response OK // already resolved
        }

        //if(res params veryVerbose) printf("\t$$$$ resolving typeArgs of %s (call = %d, ref = %d)\n", toString(), typeArgs getSize(), ref typeArgs getSize())
        //if(res params veryVerbose) printf("trail = %s\n", trail toString())

        i := typeArgs getSize()
        while(i < ref typeArgs getSize()) {
            typeArg := ref typeArgs get(i)
            //if(res params veryVerbose) printf("\t$$$$ resolving typeArg %s\n", typeArg name)

            finalScore := 0
            typeResult := resolveTypeArg(trail, res, typeArg name, finalScore&)

            if(finalScore == -1) break
            if(typeResult) {
                if (debugCondition()) {
                    token printMessage("in #{this}, resolved typeArg #{typeArg}, result = #{typeResult}")
                    token printMessage("owner is #{typeResult owner ? typeResult owner toString() : "<nil>"}")
                }
                result := match {
                    case typeResult instanceOf?(FuncType) || (typeResult pointerLevel() > 0) =>
                        VariableAccess new("Pointer", token)
                    case =>
                        if (debugCondition()) {
                            token printMessage("making an access to typeResult")
                        }
                        VariableAccess new(typeResult, token)
                }

                if (typeResult isGeneric()) {
                    result setRef(null) // force re-resolution - we may not be in the correct context
                }
                typeArgs add(result)
            } else break // typeArgs must be in order

            i += 1
        }

        for(typeArg in typeArgs) {
            if (debugCondition()) {
                "In %s, resolving typeArg %s" printfln(toString(), typeArg toString())
            }
            response := typeArg resolve(trail, res)
            if(!response ok()) {
                if(res fatal) res throwError(InternalError new(token, "Couldn't resolve typeArg %s in call %s" format(typeArg toString(), toString())))
                return response
            }
        }

        if(typeArgs getSize() != ref typeArgs getSize()) {
            if(res fatal) {
                res throwError(InternalError new(token, "Missing info for type argument %s. Have you forgotten to qualify %s, e.g. List<Int>?" format(ref typeArgs get(typeArgs getSize()) getName(), ref toString())))
            }
            res wholeAgain(this, "Looping because of typeArgs\n")
        }

        return Response OK

    }

    resolveTypeArg: func (trail: Trail, res: Resolver, typeArgName: String, finalScore: Int@) -> Type {

        if(debugCondition()) "Should resolve typeArg %s in call %s" printfln(typeArgName, toString())

        if(ref && refScore > 0) {
            if(ref genericConstraints) for(key in ref genericConstraints getKeys()) {
                if(key getName() == typeArgName) {
                    return ref genericConstraints get(key)
                }
            }

            inFunctionTypeArgs := false
            for(typeArg in ref typeArgs) {
                if(typeArg getName() == typeArgName) {
                    inFunctionTypeArgs = true
                    break
                }
            }

            if(inFunctionTypeArgs) {
                combinedResult: Type = null

                for((j, arg) in ref args) {
                    /*
                     * Use case:
                     * 
                     *   myFunction: func <T> (myArg: T)
                     *
                     * or:
                     *
                     *   myFunction: func <T> (myArg: T[])
                     *
                     * or any level of nesting
                     */
                    argType := arg type
                    refCount := 0

                    while (argType instanceOf?(SugarType)) {
                        argType = argType as SugarType inner
                        refCount += 1
                    }

                    if (argType getName() == typeArgName) {
                        implArg := args get(j)
                        match implArg {
                            case addr: AddressOf =>
                                if (addr isForGenerics) {
                                    implArg = addr expr
                                }
                        }

                        result := implArg getType()
                        if (result == null) {
                            if(debugCondition()) " >> We need the inferred return type. Looping" println()
                            finalScore = -1
                            return null
                        }

                        realCount := 0
                        while (result instanceOf?(SugarType) && realCount < refCount) {
                            result = result as SugarType inner
                            realCount += 1
                        }

                        if(realCount == refCount) {
                            if(debugCondition()) {
                                token printMessage(" >> Found arg-arg #{implArg} (of type #{implArg class name}) for typeArgName #{typeArgName}, returning #{result}")
                            }

                            match implArg {
                                case va: VariableAccess =>
                                    if (va expr) {
                                        result = result clone()
                                        result owner = va expr
                                    }
                            }
                            combineTypesHard(res, this, combinedResult&, result, "arg-arg")
                        }
                    }

                    /* myFunction: func <T> (myArg: Func -> T) */
                    if(argType instanceOf?(FuncType)) {
                        fType := argType as FuncType

                        if(fType returnType && fType returnType getName() == typeArgName) {
                            if(debugCondition()) " >> Hey, we have an interesting FuncType %s" format(fType toString()) println()
                            implArg := args get(j)
                            if(implArg instanceOf?(FunctionDecl)) {
                                fDecl := implArg as FunctionDecl
                                if(fDecl inferredReturnType) {
                                    if(debugCondition()) " >> Got it from inferred return type %s!" format(fDecl inferredReturnType toString()) println()
                                    return fDecl inferredReturnType
                                } else {
                                    if(debugCondition()) " >> We need the inferred return type. Looping" println()
                                    finalScore = -1
                                    return null
                                }
                            }
                        }
                    }

                    /* myFunction: func <T> (T: Class) */
                    if(arg getName() == typeArgName) {
                        implArg := args get(j)
                        match implArg {
                            case vAcc: VariableAccess =>
                                if(!vAcc getRef()) {
                                    finalScore == -1
                                    return null
                                }
                                result := BaseType new(vAcc getName(), implArg token)
                                result setRef(vAcc getRef())

                                if(debugCondition()) " >> Found ref-arg %s for typeArgName %s, returning %s" format(implArg toString(), typeArgName, result toString()) println()
                                return result

                            case tAcc: TypeAccess =>
                                return tAcc inner

                            case type: Type =>
                                return type
                        }
                    }
                }

                if (combinedResult) {
                    return combinedResult
                }

                /* myFunction: func <T> (myArg: OtherType<T>) */
                if (ref) {
                    // we're looking for something like 'OtherType<T>' in the function definition
                    // we want to know the index of the argument in the list, and then the index of
                    // the type arg in the argument's type. For example, if we were looking for D,
                    // the indices would be 2 (third argument) and 3 (fourth typeArg) in this:
                    //
                    // myFunction: func <A, B, C, D> (arg1: SomeType<B>, arg2: SomeType<B, C>, arg3: SomeType<A, B, C, D>)

                    result: Type = null
                    score := 0
                    ref eachTypeArgMappingUntil(typeArgName, |argIndex, realTypeArgName|
                        arg := args get(argIndex)
                        if (arg getType() == null) {
                            if (debugCondition()) "Type of arg %s is null" printfln(arg toString())
                            return true // continue
                        }

                        if (debugCondition()) "Mapped %s to %s, searching for it in %s" printfln(typeArgName, realTypeArgName, arg toString())

                        tempScore := 0
                        result = arg getType() searchTypeArg(realTypeArgName, tempScore&)
                        score = tempScore
                        if(score == -1) {
                            // something has to be resolved further!
                            return false // break
                        }
                        if(result) {
                            // we found it!
                            if(debugCondition()) "Found match for arg %s! Hence, result = %s (cause arg = %s)" printfln(typeArgName, result toString(), arg toString())
                            return false // break
                        }

                        true
                    )
                    if (result) {
                        finalScore = score
                        return result
                    }
                }

            }
        }

        if(expr != null) {
            if(expr instanceOf?(Type)) {
                /* Type<T> myFunction() */
                if(debugCondition()) "Looking for typeArg %s in expr-type %s" printfln(typeArgName, expr toString())
                result := expr as Type searchTypeArg(typeArgName, finalScore&)
                if(finalScore == -1) return null // something has to be resolved further!
                if(result) {
                    if(debugCondition()) "Found match for arg %s! Hence, result = %s (cause expr = %s)" printfln(typeArgName, result toString(), expr toString())
                    return result
                }
            } else if(expr getType() != null) {
                /* expr: Type<T>; expr myFunction() */
                if(debugCondition()) {
                    token printMessage("Looking for typeArg #{typeArgName} in expr #{expr} (of type #{expr getType()})")
                }
                result := expr getType() searchTypeArg(typeArgName, finalScore&)
                if(finalScore == -1) return null // something has to be resolved further!
                if(result) {
                    if(debugCondition()) "Found match for arg %s! Hence, result = %s (cause expr type = %s)" printfln(typeArgName, result toString(), expr getType() toString())
                    return result
                }
            }
        }

        if(trail) {
            idx := trail find(TypeDecl)
            if(idx != -1) {
                tDecl := trail get(idx, TypeDecl)
                if(debugCondition()) "\n===\nFound tDecl %s" format(tDecl toString()) println()
                for(typeArg in tDecl getTypeArgs()) {
                    if(typeArg getName() == typeArgName) {
                        result := BaseType new(typeArgName, token)
                        result setRef(typeArg)
                        return result
                    }
                }

                if(tDecl getNonMeta() != null) {
                    result := tDecl getNonMeta() getInstanceType() searchTypeArg(typeArgName, finalScore&)
                    if(finalScore == -1) return null // something has to be resolved further!
                    if(result) {
                        if(debugCondition()) "Found in-TypeDecl match for arg %s! Hence, result = %s (cause expr type = %s)" printfln(typeArgName, result toString(), tDecl getNonMeta() getInstanceType() toString())
                        return result
                    }
                }
            }

            idx = trail find(FunctionDecl)
            while(idx != -1) {
                fDecl := trail get(idx, FunctionDecl)
                if(debugCondition()) "\n===\nFound fDecl %s, with %d typeArgs" format(fDecl toString(), fDecl getTypeArgs() getSize()) println()
                for(typeArg in fDecl getTypeArgs()) {
                    if(typeArg getName() == typeArgName) {
                        result := BaseType new(typeArgName, token)
                        result setRef(typeArg)
                        return result
                    }
                }
                idx = trail find(FunctionDecl, idx - 1)
            }
        }

        if(debugCondition()) "Couldn't resolve typeArg %s" printfln(typeArgName)
        return null

    }

    /**
     * @return the score of decl, respective to this function call.
     * This is used when resolving function calls, so that the function
     * decl with the highest score is chosen as a reference.
     */
    getScore: func (decl: FunctionDecl) -> Int {
        score := 0

        declArgs := decl args
        if(matchesArgs(decl)) {
            score += Type SCORE_SEED / 4
            if(debugCondition()) {
                "matchesArg, score is now %d" printfln(score)
            }
        } else {
            if(debugCondition()) {
                "doesn't match args, too bad!" printfln(score)
            }
            return Type NOLUCK_SCORE
        }

        if(decl getOwner() != null && isMember()) {
            // Will suffice to make a member call stronger
            score += Type SCORE_SEED / 4
        }

        if(suffix == null && decl suffix == null && !decl isStatic()) {
            // even though an unsuffixed call could be a call
            // to any of the suffixed versions, if both the call
            // and the decl don't have a suffix, that's a good sign.
            // a slight boost of 1 should be enough to make rock use
            // the correct version of a function with multiple definitions
            // that have the same argument types and use the one declared
            // with no suffix.
            score += 1
        }

        if(declArgs getSize() == 0) return score

        declIter : Iterator<Argument> = declArgs iterator()
        callIter : Iterator<Expression> = args iterator()

        while(callIter hasNext?() && declIter hasNext?()) {
            declArg := declIter next()
            callArg := callIter next()
            // avoid null types
            if(declArg instanceOf?(VarArg)) break
            if(declArg getType() == null) {
                if(debugCondition()) "Score is -1 because of declArg %s\n" format(declArg toString()) println()
                return -1
            }
            if(callArg getType() == null) {
                if(debugCondition()) "Score is -1 because of callArg %s\n" format(callArg toString()) println()
                return -1
            }

            declArgType := declArg getType() refToPointer()
            if (declArgType isGeneric()) {
                declArgType = declArgType realTypize(this)
            }

            typeScore := callArg getType() getScore(declArgType)
            if(typeScore == -1) {
                if(debugCondition()) {
                    "-1 because of type score between %s and %s" printfln(callArg getType() toString(), declArgType refToPointer() toString())
                }
                return -1
            }
            if (decl isExtern()) {
                if(typeScore == Type NOLUCK_SCORE) {
                    ref := callArg getType() getRef()
                    if(ref instanceOf?(TypeDecl)) {
                        ref as TypeDecl implicitConversions each(|opdecl|
                            if(opdecl fDecl getReturnType() equals?(declArgType)) {
                                typeScore = Type SCORE_SEED / 4
                            }
                        )
                    }
                }
            }

            score += typeScore

            if(debugCondition()) {
                "typeScore for %s vs %s == %d    for call %s (%s vs %s) [%p vs %p]" printfln(
                    callArg getType() toString(), declArgType refToPointer() toString(), typeScore, toString(),
                    callArg getType() getGroundType() toString(), declArgType refToPointer() getGroundType() toString(),
                    callArg getType() getRef(), declArgType getRef())
            }
        }

        if(debugCondition()) {
            "Final score = %d" printfln(score)
        }

        return score
    }

    /**
     * Returns true if decl has a signature compatible with this function call
     */
    matchesArgs: func (decl: FunctionDecl) -> Bool {

        callIter := args iterator()
        declIter := decl args iterator()

        // deal with all the callArgs we have
        while(callIter hasNext?()) {
            if(!declIter hasNext?()) {
                if(debugCondition()) "Args don't match! Too many call args" println()
                return false
            }

            if(declIter next() instanceOf?(VarArg)) {
                if(debugCondition()) "Varargs swallow all!" println()
                // well, whatever we have left, VarArgs swallows it all.
                return true
            }

            if(debugCondition()) "Regular arg consumes one." println()
            // if not varargs, consume one callarg.
            callIter next()
        }

        // deal with remaining declArgs
        while(declIter hasNext?()) {
            declArg := declIter next()
            if(declArg instanceOf?(VarArg)) {
                if(debugCondition()) "Ending on a classy varargs." println()
                // varargs can also be omitted.
                return true
            }

            if(declArg expr) {
                // optional arg
                if(debugCondition()) "Optional arg." println()
                continue
            }
            // not an optional arg? then it's not a match, sorry m'am.
            if(debugCondition()) "Args don't match! Not enough call args" println()
            return false
        }
        true
    }

    /**
     * Prints an error if any of our arguments is invalid (aka an empty array literal)
     */
    checkArgumentValidity: func(res: Resolver) {
        for(arg in args) {
            if(arg instanceOf?(ArrayLiteral) && arg as ArrayLiteral elements empty?()) {
                res throwError(InvalidArgument new(token, "You cannot pass an empty array literal as an argument to a function"))
            }
        }
    }

    getType: func -> Type { returnType }

    isMember: func -> Bool {
        (expr != null) &&
        !(expr instanceOf?(VariableAccess) &&
          expr as VariableAccess getRef() != null &&
          expr as VariableAccess getRef() instanceOf?(NamespaceDecl)
        )
    }

    getArgsRepr: func -> String {
        sb := Buffer new()
        sb append("(")
        isFirst := true
        for(arg in args) {
            if(!isFirst) sb append(", ")
            sb append(arg ? arg toString() : "(null)")
            if(isFirst) isFirst = false
        }
        sb append(")")
        return sb toString()
    }

    getArgsTypesRepr: func -> String {
        sb := Buffer new()
        sb append("(")
        isFirst := true
        for(arg in args) {
            if(!isFirst) sb append(", ")
            sb append(arg getType() ? arg getType() toString() : "<unknown type>")
            if(isFirst) isFirst = false
        }
        sb append(")")
        return sb toString()
    }

    toString: func -> String {
        (expr ? expr toString() + " " : "") + (ref ? ref prettyName : this prettyName) + getArgsRepr()
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        if(oldie == expr) {
            expr = kiddo;
            return true;
        }

        args replace(oldie as Expression, kiddo as Expression)
    }

    setReturnArg: func (retArg: Expression) {
        if(returnArgs empty?()) {
            returnArgs add(retArg)
        } else {
            returnArgs[0] = retArg
        }
    }
    getReturnArgs: func -> List<Expression> { returnArgs }

    getRef: func -> FunctionDecl { ref }
    setRef: func (=ref) { refScore = 1; /* or it'll keep trying to resolve it =) */ }

    getArguments: func -> ArrayList<Expression> { args }

    isResolved: func -> Bool {
        refScore > 0 && ref != null && resolved
    }

}

InvalidSlurp: class extends Error {

    call: FunctionCall
    precisions: String

    init: func (.call, .message, =precisions) {
        init(call token, call, message)
    }

    init: func ~withToken(.token, =call, .message) {
        super(call expr ? call expr token enclosing(call token) : call token, message)
        precisions = ""
    }

    format: func -> String {
        token formatMessage(message, "ERROR") + precisions
    }

}

/**
 * Error thrown when a type isn't defined
 */
UnresolvedCall: class extends Error {

    call: FunctionCall

    init: func (.call, .message) {
        super(call token, message)
    }

    init: func ~withToken (.token, call: FunctionCall, message: String) {
        token = call token
        if (call expr) {
            token = call expr token enclosing(token)
        }
        super(token, message)
    }

}

InvalidArgument: class extends Error {
    init: super func ~tokenMessage
}

UseOfVoidExpression: class extends Error {
    init: super func ~tokenMessage
}

