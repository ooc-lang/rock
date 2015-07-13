import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, OperatorDecl,
       IntLiteral, Ternary, BaseType, BinaryOp, CoverDecl, VariableDecl, TypeDecl
import tinker/[Resolver, Trail, Response, Errors]

CompType: enum {
    equal
    notEqual
    greaterThan
    smallerThan
    greaterOrEqual
    smallerOrEqual
    compare
}


compTypeRepr := [
        "==",
        "!=",
        ">",
        "<",
        ">=",
        "<=",
        "<=>"]


Comparison: class extends Expression {

    left, right: Expression
    compType: CompType

    _resolved := false
    replaced := false

    type := static BaseType new("Bool", nullToken)

    init: func ~comparison (=left, =right, =compType, .token) {
        super(token)
    }

    accept: func (visitor: Visitor) {
        visitor visitComparison(this)
    }

    clone: func -> This {
        new(left clone(), right clone(), compType, token)
    }

    getType: func -> Type { This type }

    repr: func -> String {
        compTypeRepr[compType as Int - CompType equal]
    }

    toString: func -> String {
        return left toString() + " " + repr() + " " + right toString()
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if (isResolved() || replaced) {
            return Response OK
        }

        match (resolveSides(trail, res)) {
            case BranchResult BREAK => return Response OK
            case BranchResult LOOP  => return Response LOOP
        }

        match (resolveOverload(trail, res)) {
            case BranchResult BREAK => return Response OK
            case BranchResult LOOP  => return Response LOOP
        }

        if(!isLegal(res)) {
            if(res fatal) {
                res throwError(InvalidOperatorUse new(token, "Invalid comparison between operands of type %s and %s\n" format(
                    left getType() toString(), right getType() toString())))
                return Response OK
            }
            res wholeAgain(this, "Illegal use, looping in hope.")
            return Response OK
        }

        _resolved = true

        return Response OK

    }

    isResolved: func -> Bool {
        // if we've been replaced, we're not 'resolved', technically,
        // our parent needs to wholeAgain.
        _resolved && !replaced
    }

    refresh: func {
        _resolved = false
    }

    // TODO: remove duplicate code with BinaryOp -- amos

    resolveSides: func (trail: Trail, res: Resolver) -> BranchResult {
        trail push(this)

        match (left resolve(trail, res)) {
            case Response OK => // good
            case =>
                trail pop(this)
                return BranchResult LOOP
        }

        match (right resolve(trail, res)) {
            case Response OK => // good
            case =>
                trail pop(this)
                return BranchResult LOOP
        }

        match (This type resolve(trail, res)) {
            case Response OK => // good
            case =>
                trail pop(this)
                return BranchResult LOOP
        }

        trail pop(this)

        if (!left isResolved() || !right isResolved()) {
            res wholeAgain(this, "need both sides of comparison to be resolved")
            return BranchResult BREAK
        }

        if (left getType() == null || right getType() == null) {
            res wholeAgain(this, "need type of both sides")
            return BranchResult BREAK
        }

        BranchResult CONTINUE
    }

    isLegal: func (res: Resolver) -> Bool {
        (lType, rType) := (left getType(), right getType())

        if(lType == null || lType getRef() == null || rType == null || rType getRef() == null) {
            // must resolve first
            res wholeAgain(this, "Unresolved types, looping to determine legitness")
            return true
        }

        (lRef, rRef) := (lType getRef(), rType getRef())

        lCompound := lRef instanceOf?(CoverDecl) && !lRef as CoverDecl getFromType() && lType pointerLevel() == 0
        rCompound := rRef instanceOf?(CoverDecl) && !rRef as CoverDecl getFromType() && rType pointerLevel() == 0

        if(lCompound || rCompound) {
            // if either side are compound covers (structs) - it's illegal.
            return false
        }

        true
    }

    // TODO: this is, of course, duplicated in BinaryOp... :( - amos

    /**
     * Tries to find if this particular usage of an operator is covered
     * by an operator overload somewhere
     */
    resolveOverload: func (trail: Trail, res: Resolver) -> BranchResult {

        // so here's the plan: we give each operator overload a score
        // depending on how well it fits our requirements (types)

        bestScore := 0
        candidate: OperatorDecl = null

        // first we check the lhs's type
        lhsType := left getType()

        if (lhsType) {
            lhsTypeRef := lhsType getRef()

            match lhsTypeRef {
                case tDecl: TypeDecl =>
                    if (tDecl isMeta) {
                        tDecl = tDecl getNonMeta()
                    }

                    // trying to resolve as member operator overload
                    // on the lhs' type
                    for (opDecl in tDecl operators) {
                        score := getScore(opDecl)
                        if(score == -1) {
                            res wholeAgain(this, "asked to wait when resolving operator overload on type")
                            return BranchResult BREAK
                        }
                        if(score > bestScore) {
                            bestScore = score
                            candidate = opDecl
                        }
                    }
            }
        }

        // TODO: reduce code duplication here using a Cons -- amos

        // then we check the current module
        for(opDecl in trail module() getOperators()) {
            score := getScore(opDecl)
            if(score == -1) {
                res wholeAgain(this, "asked to wait when resolving operator overload in own module")
                return BranchResult BREAK
            }
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
                if (score == -1) {
                    res wholeAgain(this, "asked to wait when resolving operator overload in imported module")
                    return BranchResult BREAK
                }
                if(score > bestScore) {
                    bestScore = score
                    candidate = opDecl
                }
            }
        }

        if (candidate == null) {
            // TODO: that's not an overload, move out of this method -- amos
            if (compType == CompType compare) {
                /*
                 *   a <=> b
                 *
                 * becomes
                 *
                 *   a > b ? 1 : (a < b ? -1 : 0)
                 */
                minus := IntLiteral new(-1, token)
                zero  := IntLiteral new(0,  token)
                plus  := IntLiteral new(1,  token)
                inner := Ternary new(Comparison new(left, right, CompType smallerThan,  token), minus, zero,  token)
                outer := Ternary new(Comparison new(left, right, CompType greaterThan, token),  plus,  inner, token)

                if(!trail peek() replace(this, outer)) {
                    res throwError(CouldntReplace new(token, this, outer, trail))
                }
                replaced = true
                res wholeAgain(this, "unwrapped comparison operator <=>")
                return BranchResult BREAK
            }

            // no candidate, no need to overload
            return BranchResult CONTINUE
        }
        
        fDecl := candidate getFunctionDecl()
        fCall := FunctionCall new(fDecl getName(), token)
        fCall setRef(fDecl)
        fCall args add(left). add(right)

        node := fCall as Node

        if (candidate getSymbol() equals?("<=>")) {
            node = Comparison new(node as Expression, IntLiteral new(0, token), compType, token)
        }

        if (!trail peek() replace(this, node)) {
            if (res fatal) {
                res throwError(CouldntReplace new(token, this, node, trail))
            }
            res wholeAgain(this, "couldn't replace")
            return BranchResult BREAK
        }

        replaced = true
        res wholeAgain(this, "Just replaced with an operator overload")
        return BranchResult BREAK

    }

    getScore: func (op: OperatorDecl) -> Int {

        symbol := repr()

        half := false

        if(!(op getSymbol() equals?(symbol))) {
            if(op getSymbol() equals?("<=>")) half = true
            else return 0 // not the right overload type - skip
        }

        fDecl := op getFunctionDecl()
        args := ArrayList<VariableDecl> new()
        args addAll(fDecl getArguments())

        if (fDecl owner) {
            args add(0, fDecl owner getThisDecl())
        }

        if(args getSize() != 2) {
            token module params errorHandler onError(InvalidComparisonOverload new(op token,
                "Argl, you need 2 arguments to override the '%s' operator, not %d" format(symbol, args getSize())))
        }

        opLeft  := args get(0)
        opRight := args get(1)

        if(opLeft getType() == null || opRight getType() == null || left getType() == null || right getType() == null) {
            return -1
        }

        leftScore  := left  getType() getStrictScore(opLeft  getType())
        if(leftScore  == -1) return -1
        rightScore := right getType() getStrictScore(opRight getType())
        if(rightScore == -1) return -1

        score := leftScore + rightScore

        if (half) {
            // used to prioritize '<=', '>=', and blah, over '<=>'
            score /= 2
        }

        return score

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case left  =>
                left = kiddo
                refresh()
                true
            case right =>
                right = kiddo
                refresh()
                true
            case =>
                false
        }
    }

}

InvalidComparisonOverload: class extends Error {
    init: super func ~tokenMessage
}
