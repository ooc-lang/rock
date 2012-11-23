import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, OperatorDecl,
       Import, Module, FunctionCall, ClassDecl, CoverDecl, AddressOf,
       ArrayAccess, VariableAccess, Cast, NullLiteral, PropertyDecl,
       Tuple, VariableDecl, FuncType
import tinker/[Trail, Resolver, Response, Errors]

OpType: enum {
    add        /*  +  */
    sub        /*  -  */
    mul        /*  *  */
    exp        /*..**.*/
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
    rshiftAss  /* >>= */
    lshiftAss  /* <<= */
    bOrAss     /*  |= */
    bXorAss    /*  ^= */
    bAndAss    /*  &= */

    or         /*  || */
    and        /*  && */
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
        ">>=",
        "<<=",
        "|=",
        "^=",
        "&=",

        "||",
        "&&"]

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

    isAssign: func -> Bool { (type >= OpType ass) && (type <= OpType bAndAss) }

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
        return left toString() + " " + opTypeRepr[type] + " " + right toString()
    }

    unwrapAssign: func (trail: Trail, res: Resolver) -> Bool {
        if(!isAssign()) return false

        innerType := type - (OpType addAss - OpType add)
        inner := BinaryOp new(left, right, innerType, token)
        right = inner
        type = OpType ass

        true
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

        if(!replaced && inferredType == null) {
            // that's probably not right - for example, for integer/float types promotion, etc.
            inferredType = left getType()
        }

        if(type == OpType ass) {
            if (!left isResolved()) {
                res wholeAgain(this, "Can't resolve '%s'. (maybe you forgot to declare a variable?)" format(left toString()))
                return Response OK
            } elseif (!right isResolved()) {
                res wholeAgain(this, "Can't resolve %s. (maybe you forgot to declare a variable?" format(right toString()))
                return Response OK
            }

            if(left getType() == null || !left isResolved()) {
                res wholeAgain(this, "left type is unresolved"); return Response OK
            }
            if(right getType() == null || !right isResolved()) {
                res wholeAgain(this, "right type is unresolved"); return Response OK
            }

            // Left side is a property access? Replace myself with a setter call.
            // Make sure we're not in the getter/setter.
            if(left instanceOf?(VariableAccess) && left as VariableAccess ref instanceOf?(PropertyDecl)) {
                leftProperty := left as VariableAccess ref as PropertyDecl
                if(leftProperty inOuterSpace(trail)) {
                    fCall := FunctionCall new(left as VariableAccess expr, leftProperty getSetterName(), token)
                    fCall getArguments() add(right)
                    trail peek() replace(this, fCall)
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
            if(realRight instanceOf?(FunctionCall)) {
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
                    sizeAcc = VariableAccess new(VariableAccess new(right getType(), token), "size", token)
                } else {
                    sizeAcc = VariableAccess new(VariableAccess new(left getType(), token), "size", token)
                }


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

        // In case of a expression like `expr attribute += value` where `attribute`
        // is a property, we need to unwrap this to `expr attribute = expr attribute + value`.
        if(isAssign() && left instanceOf?(VariableAccess)) {
            if(left getType() == null || !left isResolved()) {
                res wholeAgain(this, "left type is unresolved"); return Response OK
            }
            if(right getType() == null || !right isResolved()) {
                res wholeAgain(this, "right type is unresolved"); return Response OK
            }
            // are we in a +=, *=, /=, ... operator? unwrap myself.
            if(left as VariableAccess ref instanceOf?(PropertyDecl)) {
                leftProperty := left as VariableAccess ref as PropertyDecl
                if(leftProperty inOuterSpace(trail)) {
                    // only outside of get/set.
                    unwrapAssign(trail, res)
                    trail push(this)
                    right resolve(trail, res)
                    trail pop(this)
                }
            }
        }

        // Assigning tuples need unwinding
        if(type == OpType ass && left instanceOf?(Tuple) && right instanceOf?(Tuple)) {
            t1 := left as Tuple
            t2 := right as Tuple

            if(t1 elements getSize() != t2 elements getSize()) {
                res throwError(InvalidOperatorUse new(token, "Invalid assignment between operands of type %s and %s\n" format(
                    left getType() toString(), right getType() toString())))
                return Response OK
            }

            size := t1 elements getSize()

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
                        return Response OK
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
                child := new(t1 elements[i], t2 elements[i], type, token)

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

        if(!isLegal(res)) {
            if(res fatal) {
                res throwError(InvalidOperatorUse new(token, "Invalid use of operator %s between operands of type %s and %s\n" format(
                    opTypeRepr[type], left getType() toString(), right getType() toString())))
                return Response OK
            }
            res wholeAgain(this, "Illegal use, looping in hope.")
        }

        return Response OK

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
            return (type == OpType ass)
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
            token module params errorHandler onError(InvalidBinaryOverload new(token,
                "%s is an immutable function. You must not reassign it. (Perhaps you want to use a first-class function instead?)" format(left toString())))
            }
        }

        if(isAssign()) {
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

        reqType := trail peek() getRequiredType()

        for(opDecl in trail module() getOperators()) {
            score := getScore(opDecl, reqType)
            //if(score > 0) ("Considering " + opDecl toString() + " for " + toString() + ", score = %d\n") format(score) println()
            if(score == -1) { res wholeAgain(this, "score of op == -1 !!"); return Response LOOP }
            if(score > bestScore) {
                bestScore = score
                candidate = opDecl
            }
        }

        for(imp in trail module() getAllImports()) {
            module := imp getModule()
            for(opDecl in module getOperators()) {
                score := getScore(opDecl, reqType)
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
                return Response LOOP
            }

            fDecl := candidate getFunctionDecl()
            fCall := FunctionCall new(fDecl getName(), token)
            fCall getArguments() add(left)
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

    getScore: func (op: OperatorDecl, reqType: Type) -> Int {

        symbol := opTypeRepr[type]

        half := false

        if(!(op getSymbol() equals?(symbol))) {
            if(isAssign() && symbol startsWith?(op getSymbol())) {
                // alright!
                half = true
            } else {
                return 0 // not the right overload type - skip
            }
        }

        fDecl := op getFunctionDecl()

        args := fDecl getArguments()
        if(args getSize() != 2) {
            token module params errorHandler onError(InvalidBinaryOverload new(op token,
                "Argl, you need 2 arguments to override the '%s' operator, not %d" format(symbol, args getSize())))
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

        reqScore   := reqType ? fDecl getReturnType() getScore(reqType) : 0
        if(reqScore   == -1) return -1

        //printf("leftScore = %d, rightScore = %d\n", leftScore, rightScore)

        score := leftScore + rightScore + reqScore

        if(half) score /= 2  // used to prioritize '+=', '-=', and blah, over '+ and =', etc.

        return score

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case left  => left  = kiddo; true
            case right => right = kiddo; true
            case => false
        }
    }

}

InvalidBinaryOverload: class extends Error {
    init: super func ~tokenMessage
}

InvalidOperatorUse: class extends Error {
    init: super func ~tokenMessage
}
