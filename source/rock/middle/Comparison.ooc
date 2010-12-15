import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, OperatorDecl,
       IntLiteral, Ternary, BaseType, BinaryOp, CoverDecl
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


compTypeRepr := ["no-op",
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

    toString: func -> String {
        return left toString() + " " + compTypeRepr[compType] + " " + right toString()
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
        {
            response := This type resolve(trail, res)
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

        if(!isLegal(res)) {
            if(res fatal) {
                res throwError(InvalidOperatorUse new(token, "Invalid comparison between operands of type %s and %s\n" format(
                    left getType() toString(), right getType() toString())))
                return Response OK
            }
            res wholeAgain(this, "Illegal use, looping in hope.")
        }

        return Response OK

    }

    isLegal: func (res: Resolver) -> Bool {
        (lType, rType) := (left getType(), right getType())

        if(lType == null || lType getRef() == null || rType == null || rType getRef() == null) {
            // must resolve first
            res wholeAgain(this, "Unresolved types, looping to determine legitness")
            return true
        }

        (lRef, rRef) := (lType getRef(), rType getRef())

        lCompound := lRef instanceOf?(CoverDecl) && !lRef as CoverDecl getFromType()
        rCompound := rRef instanceOf?(CoverDecl) && !rRef as CoverDecl getFromType()

        if(lCompound || rCompound) {
            // if either side are compound covers (structs) - it's illegal.
            return false
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

        if(candidate == null) {

            if(compType == CompType compare) {
                // a <=> b
                // a > b ? 1 : (a < b ? -1 : 0)

                minus := IntLiteral new(-1, token)
                zero  := IntLiteral new(0,  token)
                plus  := IntLiteral new(1,  token)
                inner := Ternary new(Comparison new(left, right, CompType smallerThan,  token), minus, zero,  token)
                outer := Ternary new(Comparison new(left, right, CompType greaterThan, token),  plus,  inner, token)

                if(!trail peek() replace(this, outer)) {
                    res throwError(CouldntReplace new(token, this, outer, trail))
                }
            }

        } else {
            fDecl := candidate getFunctionDecl()
            fCall := FunctionCall new(fDecl getName(), token)
            fCall setRef(fDecl)
            fCall getArguments() add(left)
            fCall getArguments() add(right)
            node := fCall as Node

            if(candidate getSymbol() equals?("<=>")) {
                node = Comparison new(node as Expression, IntLiteral new(0, token), compType, token)
            }

            if(!trail peek() replace(this, node)) {
                if(res fatal) res throwError(CouldntReplace new(token, this, node, trail))
                res wholeAgain(this, "failed to replace oneself, gotta try again =)")
                return Response LOOP
            }
            res wholeAgain(this, "Just replaced with an operator overloading")
        }

        return Response OK

    }

    getScore: func (op: OperatorDecl, reqType: Type) -> Int {

        symbol := compTypeRepr[compType]

        half := false

        if(!(op getSymbol() equals?(symbol))) {
            if(op getSymbol() equals?("<=>")) half = true
            else return 0 // not the right overload type - skip
        }

        fDecl := op getFunctionDecl()

        args := fDecl getArguments()
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
        reqScore   := reqType ? fDecl getReturnType() getScore(reqType) : 0
        if(reqScore   == -1) return -1

        score := leftScore + rightScore + reqScore

        if(half) score /= 2  // used to prioritize '<=', '>=', and blah, over '<=>'

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

InvalidComparisonOverload: class extends Error {
    init: super func ~tokenMessage
}
