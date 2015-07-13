import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, OperatorDecl,
       Import, Module, FunctionCall, ClassDecl, CoverDecl, AddressOf,
       ArrayAccess, VariableAccess, Cast, NullLiteral, PropertyDecl,
       Tuple, VariableDecl, FuncType, TypeDecl, StructLiteral, TypeList,
       Scope, TemplateDef, Ternary, Comparison
import tinker/[Trail, Resolver, Response, Errors]
import algo/typeAnalysis

OpType: enum {
    add        /*  +  */
    sub        /*  -  */
    mul        /*  *  */
    exp        /*  ** */
    div        /*  /  */
    mod        /*  %  */
    rshift     /*  >> */
    lshift     /*  << */
    bOr        /*  |  */
    bXor       /*  ^  */
    bAnd       /*  &  */

    doubleArr  /*  => */
    ass        /*  =  */

    addAss     /*  += */
    subAss     /*  -= */
    mulAss     /*  *= */
    expAss     /*.**=.*/
    divAss     /*  /= */
    modAss     /*  %= */
    rshiftAss  /* >>= */
    lshiftAss  /* <<= */
    bOrAss     /*  |= */
    bXorAss    /*  ^= */
    bAndAss    /*  &= */

    or         /*  || */
    and        /*  && */

    nullCoal   /* ?? */
}

opTypeRepr := [
        "+",
        "-",
        "*",
        "**",
        "/",
        "%",
        ">>",
        "<<",
        "|",
        "^",
        "&",

        "=>",
        "=",
        "+=",
        "-=",
        "*=",
        "**=",
        "/=",
        "%=",
        ">>=",
        "<<=",
        "|=",
        "^=",
        "&=",

        "||",
        "&&",

        "??"]

BinaryOp: class extends Expression {

    left, right: Expression
    type: OpType

    inferredType: Type
    replaced := false

    init: func ~binaryOp (=left, =right, =type, .token) {
        super(token)
    }

    clone: func -> This {
        new(left clone(), right clone(), type, token)
    }

    isAssign: func -> Bool {
        (type >= OpType ass) && (type <= OpType bAndAss)
    }

    isCompositeAssign: func -> Bool {
        (type >= OpType addAss) && (type <= OpType bAndAss)
    }

    isBooleanOp: func -> Bool { type == OpType or || type == OpType and }

    accept: func (visitor: Visitor) {
        visitor visitBinaryOp(this)
    }

    // It's just an access, it has no side-effects whatsoever
    hasSideEffects : func -> Bool { !isAssign() }

    getType: func -> Type { inferredType }

    getLeft:  func -> Expression { left  }
    getRight: func -> Expression { right }

    toString: func -> String {
        return left toString() + " " + repr() + " " + right toString()
    }

    repr: func -> String {
      opTypeRepr[type as Int - OpType add]
    }

    unwrapAssign: func (trail: Trail, res: Resolver) -> Bool {
        if(!isCompositeAssign()) return false

        unwrapGetter := func(e: Expression) -> Expression{
            if(e instanceOf?(VariableAccess) && e as VariableAccess ref instanceOf?(PropertyDecl)) {
                ep := e as VariableAccess ref as PropertyDecl
                if(ep inOuterSpace(trail)) {
                    fCall := FunctionCall new(e as VariableAccess expr, ep getGetterName(), token)
                    trail push(this)
                    fCall resolve(trail, res)
                    trail pop(this)
                    return fCall
                }
            }
            e
        }
        innerType := type - (OpType addAss - OpType add)
        // very important to clone left! otherwise generics won't play well
        // (behave differently when lhs or rhs, cf. #889)
        inner := BinaryOp new(unwrapGetter(left clone()), unwrapGetter(right), innerType, token)
        right = inner
        type = OpType ass

        true
    }

    handleTuples: func (trail: Trail, res: Resolver) {
        match left {
            case t1: Tuple =>
                match right {
                    case t2: Tuple =>
                        unwrapTupleTupleAssign(t1, t2, trail, res)
                    case call: FunctionCall =>
                        unwrapTupleCallAssign(t1, call, trail, res)
                    case =>
                        message := "Invalid tuple usage: assignment rhs has incompatible type"
                        res throwError(InvalidTupleUse new(token, message))
                }
            case =>
                match right {
                    case sl: StructLiteral =>
                        // assigning struct literals is fine.
                    case t2: Tuple =>
                        message := "Invalid tuple usage: assignment lhs needs to be a tuple"
                        res throwError(InvalidTupleUse new(token, message))
                }
        }
    }

    unwrapTupleCallAssign: func (tuple: Tuple, fCall: FunctionCall, trail: Trail, res: Resolver) {
        if(fCall getRef() == null) {
            res wholeAgain(this, "Need fCall ref")
            return
        }

        if(fCall getRef() getReturnArgs() empty?()) {
            if(res fatal) {
                res throwError(TupleMismatch new(token, "Need a multi-return function call as the expression of a tuple-variable declaration."))
            }
            res wholeAgain(this, "need multi-return func call")
            return
        }

        returnArgs := fCall getReturnArgs()
        returnType := fCall getRef() getReturnType() as TypeList
        returnTypes := returnType types

        // If the tuple has fewer elements...
        if(tuple getElements() getSize() < returnTypes getSize()) {
            bad := false
            // empty is always invalid (also not parsable, probably)
            if(tuple getElements() empty?()) {
                bad = true
            } else {
                // the only case is where the last element is a VariableAccess...
                element := tuple getElements() last()
                if(!element instanceOf?(VariableAccess)) {
                    message := "Expected a variable access in a tuple-variable declaration!"
                    res throwError(InvalidTupleUse new(element token, message))
                    return
                }
                // ...that has the name '_' - which means 'soak / ignore the rest of the values'
                if(element as VariableAccess getName() != "_") {
                    bad = true
                }
            }
            if(bad) res throwError(TupleMismatch new(tuple token, "Tuple variable declaration doesn't match return type %s of function %s" format(returnType toString(), fCall getName())))
        }

        j := 0
        for(element in tuple getElements()) {
            match element {
                case vAcc: VariableAccess =>
                    argName := vAcc getName()
                    if(argName == "_") {
                        // '_' are skipped
                        returnArgs add(null)
                    } else {
                        // others are added as the call's returnArgs
                        returnArgs add(vAcc)
                    }
                case =>
                    message := "Expected a variable access in a tuple-variable declaration!"
                    res throwError(InvalidTupleUse new(element token, message))
                    return
            }
            j += 1
        }
        if (!trail addBeforeInScope(this, fCall)) {
            res throwError(CouldntAddBeforeInScope new(token, this, fCall, trail))
        }

        parent := trail peek()
        match parent {
            case s: Scope =>
                s remove(this)
                res wholeAgain(this, "replaced assignment with fCall and its returnArgs")
            case =>
                message := "Tuple / functionCall assignment in a strange place"
                res throwError(InvalidTupleUse new(token, message))
        }
    }

    unwrapTupleTupleAssign: func (t1: Tuple, t2: Tuple, trail: Trail, res: Resolver) {
        if(t1 elements getSize() != t2 elements getSize()) {
            message := "Invalid assignment (incompatible tuples) between types %s and %s\n" format(
                left getType() toString(), right getType() toString())
            res throwError(InvalidOperatorUse new(token, message))
            return
        }

        size := t1 elements getSize()

        /*
         * fix tuple swap such like (a,b) = (a,a+b)
         * if an expression in right side is not VariableAccess it will be reduced
         * to VariableAccess with temp variable
         */
        for(i in 0..size){
            r := t2 elements[i]
            if(!r instanceOf?(VariableAccess)){
                tmpDecl := VariableDecl new(null, generateTempName("exchange_r_in_t2"), r, r token)
                if(!trail addBeforeInScope(this, tmpDecl)) {
                    res throwError(CouldntAddBeforeInScope new(token, this, tmpDecl, trail))
                }
                t2 elements[i] = VariableAccess new(tmpDecl, tmpDecl token)
            }
        }

        for(i in 0..size) {
            l := t1 elements[i]
            if(!l instanceOf?(VariableAccess)) continue
            la := l as VariableAccess

            for(j in i..size) {
                r := t2 elements[j]
                if(!r instanceOf?(VariableAccess)) continue

                ra := r as VariableAccess
                if(la getRef() == null || ra getRef() == null) {
                    res wholeAgain(this, "need ref")
                    return
                }
                if(la getRef() == ra getRef()) {
                    if(i == j) {
                        useless := false
                        if(la expr != null && ra expr != null) {
                            if(la expr instanceOf?(VariableAccess) &&
                                ra expr instanceOf?(VariableAccess)) {
                                    lae := la expr as VariableAccess
                                    rae := ra expr as VariableAccess
                                    if(lae getRef() == rae getRef()) {
                                        useless = true
                                    }
                            }
                        } else {
                            useless = true
                        }
                        if(useless) { continue }
                    }

                    tmpDecl := VariableDecl new(null, generateTempName(la getName()), la, la token)
                    if(!trail addBeforeInScope(this, tmpDecl)) {
                        res throwError(CouldntAddBeforeInScope new(token, this, tmpDecl, trail))
                    }
                    t2 elements[j] = VariableAccess new(tmpDecl, tmpDecl token)
                }
            }
        }

        for(i in 0..t1 elements getSize()) {
            ignore := false

            lhs := t1 elements[i]
            rhs := t2 elements[i]

            match lhs {
                case va: VariableAccess =>
                    if (va getName() == "_") {
                        ignore = true
                    }
            }

            if (ignore) continue

            child := new(lhs, rhs, type, token)

            if(i == t1 elements getSize() - 1) {
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
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)

        {
            response := left resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        {
            response := right resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        trail pop(this)

        {
            response := resolveOverload(trail, res)
            if(!response ok()) return Response OK // needs another resolve later
        }

        {
            // findCommonRoot need both left and right is resolved

            if (!left isResolved()) {
                res wholeAgain(this, "Can't resolve '%s'. (maybe you forgot to declare a variable?)" format(left toString()))
                return Response OK
            } else if (!right isResolved()) {
                res wholeAgain(this, "Can't resolve %s. (maybe you forgot to declare a variable?" format(right toString()))
                return Response OK
            }

            if(left getType() == null || !left isResolved()) {
                res wholeAgain(this, "left type is unresolved")
                return Response OK
            }
            if(right getType() == null || !right isResolved()) {
                res wholeAgain(this, "right type is unresolved")
                return Response OK
            }
        }


        if(!replaced && inferredType == null) {
            inferredType = findCommonRoot(left getType(), right getType())
            // if fails to infer, type equals to left
            if(inferredType == null) inferredType = left getType()
            if(!inferredType isResolved()){
                res wholeAgain(this, "just gussed the common root")
                return inferredType resolve(trail, res)
            }
        }

        if(type == OpType ass) {
            // Handle tuples?
            hasTuples := left instanceOf?(Tuple) || right instanceOf?(Tuple)
            if(hasTuples) {
                // Assigning tuples need unwrapping
                handleTuples(trail, res)
            }

            // Left side is a property access? Replace myself with a setter call.
            // Make sure we're not in the getter/setter.
            if(left instanceOf?(VariableAccess) && left as VariableAccess ref instanceOf?(PropertyDecl)) {
                leftProperty := left as VariableAccess ref as PropertyDecl
                if(leftProperty inOuterSpace(trail)) {
                    fCall := FunctionCall new(left as VariableAccess expr, leftProperty getSetterName(), token)
                    fCall getArguments() add(right)
                    trail peek() replace(this, fCall)
                    res wholeAgain(this, "just replaced setter")
                    return Response OK
                } else {
                    // We're in a setter/getter. This means the property is not virtual.
                    leftProperty setVirtual(false)
                }
            }

            cast : Cast = null
            realRight := right
            if(right instanceOf?(Cast)) {
                cast = right as Cast
                realRight = cast inner
            }

            // if we're an assignment from a generic return value
            // we need to set the returnArg to left and disappear! =)
            if(realRight instanceOf?(FunctionCall) && !hasTuples) {
                fCall := realRight as FunctionCall
                fDecl := fCall getRef()
                if(!fDecl || !fDecl getReturnType() isResolved()) {
                    res wholeAgain(this, "Need more info on fDecl")
                    return Response OK
                }

                if(!fDecl getReturnArgs() empty?()) {
                    fCall setReturnArg(fDecl getReturnType() isGeneric() ? left getGenericOperand() : left)
                    trail peek() replace(this, fCall)
                    res wholeAgain(this, "just replaced with fCall and set ourselves as returnArg")
                    return Response OK
                }
            }

            if(isGeneric()) {
                sizeAcc: VariableAccess
                if(!right getType() isGeneric()) {
                    sizeAcc = VariableAccess new(right getType(), token)
                } else {
                    sizeAcc = VariableAccess new(left getType(), token)
                }
                sizeAcc = VariableAccess new(sizeAcc, "size", token)


                fCall := FunctionCall new("memcpy", token)

                fCall args add(left  getGenericOperand())
                fCall args add(right getGenericOperand())
                fCall args add(sizeAcc)
                result := trail peek() replace(this, fCall)

                if(!result) {
                    if(res fatal) res throwError(CouldntReplace new(token, this, fCall, trail))
                }

                res wholeAgain(this, "Replaced ourselves, need to tidy up")
                return Response OK
            }
        }

        // Do we need to unwrap `a += b` to `a = a + b` ?
        if (!checkUnwrapAssign(trail, res)) return Response OK

        // We must replace the null-coalescing operator with a ternary operator
        if(type == OpType nullCoal) {
            // The final expression we want is (left != null ? left : right)
            condition := Comparison new(left, NullLiteral new(token), CompType notEqual, token)
            ternary := Ternary new(condition, left, right, token)

            if(!trail peek() replace(this, ternary)) {
                if(res fatal) res throwError(CouldntReplace new(token, this, ternary, trail))
                res wholeAgain(this, "failed to replace oneself, gotta try again =)")
                return Response LOOP
            }

            res wholeAgain(this, "replaced null coalescing operator with ternary")
            return Response OK
        }

        if(!isLegal(res)) {
            if(res fatal) {
                res throwError(InvalidOperatorUse new(token, "Invalid use of operator %s between operands of type %s and %s\n" format(
                    repr(), left getType() toString(), right getType() toString())))
                return Response OK
            }
            res wholeAgain(this, "Illegal use, looping in hope.")
        }

        return Response OK

    }

    _checkUnwrapAssignDone := false

    /**
     * Check if we need to unwrap `a += b` into `a = a + b`
     * @return false if the resolving process for this node needs to
     * stop for now (ie. after wholeAgain), true if it's all good.
     */
    checkUnwrapAssign: func (trail: Trail, res: Resolver) -> Bool {

        if (!isCompositeAssign()) {
            // well that was quick
            _checkUnwrapAssignDone = true
            return true
        }

        if (!left instanceOf?(VariableAccess)) {
            // easy one too
            _checkUnwrapAssignDone = true
            return true
        }

        lhsType := left getType()
        rhsType := right getType()

        if(lhsType == null || lhsType getRef() == null) {
            res wholeAgain(this, "need left type & its ref")
            return false
        }

        if(rhsType == null || rhsType getRef() == null) {
            res wholeAgain(this, "need right type & its ref")
            return false
        }

        lhs := left as VariableAccess
        lhsRef := lhs getRef()

        match lhsRef {
            // property assignment (calling setters and getters) only works if we unwrap
            case lhsPropDecl: PropertyDecl =>
                if(!lhsPropDecl inOuterSpace(trail)) {
                    // we're inside a property getter or setter, regular
                    // rules do not apply (ie. never unwrap)
                    _checkUnwrapAssignDone = true
                    return true
                }

            // generic access / assignment of generic members only works if we unwrap
            case lhsVarDecl: VariableDecl =>
                lhsVarDeclType := lhsVarDecl getType()
                if (lhsVarDeclType == null || lhsVarDeclType getRef() == null) {
                    res wholeAgain(this, "need lhs var decl type & its ref")
                    return false
                }

                if (!lhsVarDeclType isGeneric()) {
                    // no need to unwrap non-property, non-generic stuff
                    _checkUnwrapAssignDone = true
                    return true
                }
        }

        // if we reach here, we need to unwrap!
        unwrapAssign(trail, res)

        res wholeAgain(this, "just unwrapped!")
        _checkUnwrapAssignDone = true
        return false
    }

    isGeneric: func -> Bool {
        (left  getType() isGeneric() && left  getType() pointerLevel() == 0) ||
        (right getType() isGeneric() && right getType() pointerLevel() == 0)
    }

    isLegal: func (res: Resolver) -> Bool {
        (lType, rType) := (left getType(), right getType())

        if(lType == null || lType getRef() == null || rType == null || rType getRef() == null) {
            // must resolve first
            res wholeAgain(this, "Unresolved types, looping to determine legitness")
            return true
        }

        (lRef, rRef) := (lType getRef(), rType getRef())

        if(lType isPointer() || lType pointerLevel() > 0) {
            // pointer arithmetic: you can add, subtract, and assign pointers
            return (type == OpType add ||
                    type == OpType sub ||
                    type == OpType addAss ||
                    type == OpType subAss ||
                    type == OpType ass)
        }
        if(lRef instanceOf?(ClassDecl) ||
           rRef instanceOf?(ClassDecl)) {
            // you can only assign - all others must be overloaded
            return (type == OpType ass || isBooleanOp())
        }

        lCompound := lRef instanceOf?(CoverDecl) && !lRef as CoverDecl getFromType()
        rCompound := rRef instanceOf?(CoverDecl) && !rRef as CoverDecl getFromType()

        if(lCompound ^ rCompound) {
            // if only one of the sides are compound covers (structs) - it's illegal.
            return false
        }

        if(lCompound || rCompound) {
            // you can only assign compound covers (structs), others must be overloaded
            if (type == OpType ass) {
                // template instances can be incompatible
                lDecl := lRef as CoverDecl
                rDecl := rRef as CoverDecl
                lTemplate := lDecl templateParent
                rTemplate := rDecl templateParent

                if (!!lTemplate ^ !!rTemplate) {
                    // only one of them are templates - it's illegal
                    return false
                }

                if (!!lTemplate && !!rTemplate) {
                    lTemplateArgs := lDecl templateArgs
                    rTemplateArgs := rDecl templateArgs

                    // both templates, must check that TemplateDefs match
                    if (lTemplateArgs size != rTemplateArgs size) {
                        // no way this'll work
                        return false
                    }

                    matches := true
                    lTemplateArgs each(|key, lTemplateArg|
                        rTemplateArg := rTemplateArgs get(key) 
                        if (rTemplateArg) {
                            if (lTemplateArg != rTemplateArg) {
                                matches = false
                            }
                        } else {
                            matches = false
                        }
                    )
                    if (!matches) {
                        return false
                    }
                } else {
                    // no templates at all, that's okay
                    return true
                }
            } else {
                return false
            }
        }

        lCover := lRef instanceOf?(CoverDecl)
        rCover := rRef instanceOf?(CoverDecl)
        if((!lCompound || !rCompound) && (lCover || rCover)) {
            // If a C struct is involved then we check whether the operator has a C "meaning" and thus can be translated to itself in C. If it does not, it is not valid without an overload
            if(type == OpType exp || type == OpType expAss || type == OpType doubleArr) return false
        }

        if (lRef instanceOf?(FuncType) || rRef instanceOf?(FuncType)) {
            // By default, only assignment should be allowed when a Func-type is involved.
            // Exception, of course, is an overloaded operator.
            if (!isAssign()) {
                return false
            }

            // If the left side is an immutable function, fail immediately.
            l := lRef as FuncType
            if (!(l isClosure)) {
            token module params errorHandler onError(InvalidOperatorUse new(token,
                "%s is an immutable function. You must not reassign it. (Perhaps you want to use a first-class function instead?)" format(left toString())))
            }
        }

        if(isAssign()) {
            // You can assign expressions of equal types
            if(lType equals?(rType)) return true

            score := lType getScore(rType)
            if(score == -1) {
                // must resolve first
                res wholeAgain(this, "Unresolved types, looping to determine legitness")
                return true
            }
            if(score < 0) return false
        }

        true
    }

    resolveOverload: func (trail: Trail, res: Resolver) -> Response {

        // so here's the plan: we give each operator overload a score
        // depending on how well it fits our requirements (types)

        bestScore := 0
        candidate : OperatorDecl = null

        // first we check the lhs's type
        lhsType := left getType()

        if (lhsType) {
            lhsTypeRef := lhsType getRef()

            match lhsTypeRef {
                case tDecl: TypeDecl =>
                    if (tDecl isMeta) {
                        tDecl = tDecl getNonMeta()
                    }

                    for (opDecl in tDecl operators) {
                        score := getScore(opDecl)
                        if(score == -1) {
                            return Response LOOP
                        }
                        if(score > bestScore) {
                            bestScore = score
                            candidate = opDecl
                        }
                    }
            }
        }

        // then we check the current module
        for(opDecl in trail module() getOperators()) {
            score := getScore(opDecl)
            //if(score > 0) ("Considering " + opDecl toString() + " for " + toString() + ", score = %d\n") format(score) println()
            if(score == -1) { res wholeAgain(this, "score of op == -1 !!"); return Response LOOP }
            if(score > bestScore) {
                bestScore = score
                candidate = opDecl
            }
        }

        // and then the imports
        for(imp in trail module() getAllImports()) {
            module := imp getModule()
            for(opDecl in module getOperators()) {
                score := getScore(opDecl)
                //if(score > 0) ("Considering " + opDecl toString() + " for " + toString() + ", score = %d\n") format(score) println()
                if(score == -1) { res wholeAgain(this, "score of op == -1 !!"); return Response LOOP }
                if(score > bestScore) {
                    bestScore = score
                    candidate = opDecl
                }
            }
        }

        if(candidate != null) {
            if(isAssign() && !candidate getSymbol() endsWith?("=")) {
                // we need to unwrap first!
                unwrapAssign(trail, res)
                trail push(this)
                right resolve(trail, res)
                trail pop(this)
                res wholeAgain(this, "just unwrapped assign")
                return Response OK
            }

            fDecl := candidate getFunctionDecl()
            fCall := FunctionCall new(fDecl getName(), token)

            if (fDecl owner) {
                fCall expr = left
            } else {
                fCall getArguments() add(left)
            }

            fCall getArguments() add(right)
            fCall setRef(fDecl)
            if(!trail peek() replace(this, fCall)) {
                if(res fatal) res throwError(CouldntReplace new(token, this, fCall, trail))
                res wholeAgain(this, "failed to replace oneself, gotta try again =)")
                return Response LOOP
            }
            replaced = true
            res wholeAgain(this, "Just replaced with an operator overload")
        }

        return Response OK

    }

    getScore: func (op: OperatorDecl) -> Int {

        symbol := repr()

        half := 0

        if(!(op getSymbol() equals?(symbol))) {
            if(isAssign() && symbol startsWith?(op getSymbol())) {
                s1 := op getSymbol()
                while (half < symbol size && half < s1 size && symbol[half] == s1[half]) {
                    half += 1
                }
                half = symbol size - half
            } else {
                return 0 // not the right overload type - skip
            }
        }

        fDecl := op getFunctionDecl()
        args := ArrayList<VariableDecl> new()
        args addAll(fDecl getArguments())

        if (fDecl owner) {
            args add(0, fDecl owner getThisDecl())
        }

        if (args size < 2) {
            return 0 // not the right overload type -- skip
        }

        opLeft  := args get(0)
        opRight := args get(1)

        if(opLeft getType() == null || opRight getType() == null || left getType() == null || right getType() == null) {
            return -1
        }

        leftScore  := left  getType() getScore(opLeft  getType())
        if(leftScore  == -1) return -1

        rightScore := right getType() getScore(opRight getType())
        if(rightScore == -1) return -1

        //printf("leftScore = %d, rightScore = %d\n", leftScore, rightScore)

        score := leftScore + rightScore

        if (half > 0) {
            // used to prioritize '+=', '-=', and blah, over '+ and =', etc.
            score /= half + 1
        }

        return score

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case left  => left  = kiddo; true
            case right => right = kiddo; true
            case => false
        }
    }

    /**
     * Try to find the type for a given expression, if any
     */
    typeForExpr: func (trail: Trail, expr: Expression, target: Type@) -> SearchResult {
        if (isAssign() && expr == right) {
            type := left getType()
            if (type == null) {
                // might be resolved later?
                return SearchResult RETRY
            } else {
                target = type
                return SearchResult FOUND
            }
        }

        return SearchResult NONE
    }

}

InvalidOperatorUse: class extends Error {
    init: super func ~tokenMessage
}
