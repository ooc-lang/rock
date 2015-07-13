import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, OperatorDecl, BaseType, TypeDecl, VariableDecl
import tinker/[Trail, Resolver, Response, Errors]

UnaryOpType: enum {
    binaryNot        /*  ~  */
    logicalNot       /*  !  */
    unaryMinus       /*  -  */
    unaryPlus        /*  +  */
}

unaryOpRepr := [
	"~",
        "!",
        "-",
        "+"]

UnaryOp: class extends Expression {

    inner: Expression
    type: UnaryOpType
    boolType: BaseType

    _resolved := false
    replaced := false

    init: func ~unaryOp (=inner, =type, .token) {
        super(token)
        boolType = BaseType new("Bool", token)
    }

    clone: func -> This {
        new(inner clone(), type, token)
    }

    accept: func (visitor: Visitor) {
        visitor visitUnaryOp(this)
    }

    getType: func -> Type {
        if (type == UnaryOpType logicalNot) return boolType
        inner getType()
    }

    repr: func -> String {
        unaryOpRepr[type as Int - UnaryOpType binaryNot]
    }

    toString: func -> String {
        return repr() + inner toString()
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        match (resolveInsides(trail, res)) {
            case BranchResult BREAK => return Response OK
            case BranchResult LOOP  => return Response LOOP
        }

        match (resolveOverload(trail, res)) {
            case BranchResult BREAK => return Response OK
            case BranchResult LOOP  => return Response LOOP
        }

        match (checkOperandTypes(trail, res)) {
            case BranchResult BREAK => return Response OK
            case BranchResult LOOP  => return Response LOOP
        }

        checkOperandTypes(trail, res)

        _resolved = true

        return Response OK

    }

    resolveInsides: func (trail: Trail, res: Resolver) -> BranchResult {
        trail push(this)

        boolType resolve(trail, res)

        match (inner resolve(trail, res)) {
            case Response OK => // good
            case =>
                trail pop(this)
                return BranchResult LOOP
        }

        trail pop(this)

        if (!inner isResolved() || inner getType() == null) {
            res wholeAgain(this, "need type of inner in unaryop")
            return BranchResult BREAK
        }

        BranchResult CONTINUE
    }

    checkOperandTypes: func (trail: Trail, res: Resolver) -> BranchResult {
        match type {
            case UnaryOpType unaryMinus || UnaryOpType unaryPlus =>
                // proceed to checkint area
            case =>
                // everything else is fine
                return BranchResult CONTINUE
        }

        // Unary minus can only be applied to numeric types
        if(!inner getType() isNumericType()) {
            message := "Invalid operand type '%s' for operator '%s'" format(inner getType() toString(), repr())
            error := InvalidUnaryType new(token, message)
            res throwError(error)
            return BranchResult BREAK
        }

        BranchResult CONTINUE
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

        // first we check the inner's type
        innerType := inner getType()

        if (innerType) {
            innerTypeRef := innerType getRef()

            match innerTypeRef {
                case tDecl: TypeDecl =>
                    if (tDecl isMeta) {
                        tDecl = tDecl getNonMeta()
                    }

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
                if(score == -1) {
                    res wholeAgain(this, "asked to wait when resolving operator overload in own module")
                    return BranchResult BREAK
                }
                if(score > bestScore) {
                    bestScore = score
                    candidate = opDecl
                }
            }
        }

        match candidate {
            case null =>
                // All good!
                BranchResult CONTINUE
            case =>
                // found one? replace it.
                replaceWithOverload(trail, res, candidate)
        }
    }

    replaceWithOverload: func (trail: Trail, res: Resolver, candidate: OperatorDecl) -> BranchResult {

        fDecl := candidate getFunctionDecl()
        fCall := FunctionCall new(fDecl getName(), token)
        fCall getArguments() add(inner)
        fCall setRef(fDecl)

        if(!trail peek() replace(this, fCall)) {
            if(res fatal) {
                res throwError(CouldntReplace new(token, this, fCall, trail))
                return BranchResult BREAK
            }
            res wholeAgain(this, "failed to replace operator usage with an overload")
            return BranchResult BREAK
        }

        replaced = true
        res wholeAgain(this, "just replaced with overload")
        BranchResult BREAK

    }

    getScore: func (op: OperatorDecl) -> Int {

        symbol := repr()

        if(!(op getSymbol() equals?(symbol))) {
            return 0 // not the right overload type - skip
        }

        fDecl := op getFunctionDecl()
        args := ArrayList<VariableDecl> new()
        args addAll(fDecl getArguments())

        if (fDecl owner) {
            args add(0, fDecl owner getThisDecl())
        }

        //if we have 2 arguments, then it's a binary plus binary
        if(args getSize() == 2) return 0

        if(args getSize() != 1) {
            token module params errorHandler onError(InvalidUnaryOverload new(op token,
                "You need 1 argument to override the '%s' operator, not %d" format(symbol, args getSize())))
        }

        if(args get(0) getType() == null || inner getType() == null) { return -1 }

        argScore := args get(0) getType() getScore(inner getType())
        if(argScore == -1) return -1

        return argScore

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case inner =>
                inner = kiddo
                refresh()
                true
            case => false
        }
    }

    refresh: func {
        _resolved = false
    }

    isResolved: func -> Bool {
        _resolved && !replaced
    }

}

InvalidUnaryOverload: class extends Error {
    init: super func ~tokenMessage
}

InvalidUnaryType: class extends Error {
    init: super func ~tokenMessage
}

