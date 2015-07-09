import structs/ArrayList
import ../frontend/[Token, BuildParams]
import Expression, Visitor, Type, Node, FunctionCall, VariableDecl,
       VariableAccess, BinaryOp, ArrayCreation, OperatorDecl,
       ArrayLiteral, Module
import tinker/[Response, Resolver, Trail, Errors]

Cast: class extends Expression {

    inner: Expression
    type: Type

    resolved := false

    init: func ~cast (=inner, =type, .token) {
        super(token)
    }

    clone: func -> This {
        new(inner clone(), type clone(), token)
    }

    accept: func (visitor: Visitor) {
        visitor visitCast(this)
    }

    getType: func -> Type { type }

    toString: func -> String {
        return inner toString() + " as " + type toString()
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)

        {
            response := inner resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        {
            response := type resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        trail pop(this)

        {
            response := resolveOverload(trail, res)
            if(!response ok()) return response
        }

        // Guards

        innerType := inner getType()
        if (!innerType || innerType getRef() == null) {
            res wholeAgain(this, "needs innerType")
            return Response OK
        }

        groundType := innerType getGroundType()
        if (groundType == null || groundType getRef() == null) {
            res wholeAgain(this, "need ground type of innerType")
            return Response OK
        }

        // Casting to an arrayType isn't innocent

        if(type instanceOf?(ArrayType) && !innerType instanceOf?(ArrayType)) {
            arrType := type as ArrayType
            parent := trail peek()

            if(parent instanceOf?(VariableDecl)) {
                varDecl := parent as VariableDecl
                varDecl setType(null)
                varDecl setExpr(ArrayCreation new(type as ArrayType, token))

                declAcc := VariableAccess new(varDecl, token)
                arrTypeAcc := VariableAccess new(arrType inner, token)

                sizeExpr : Expression = (arrType expr ? arrType expr : VariableAccess new(declAcc, "length", token))
                copySize := BinaryOp new(sizeExpr, VariableAccess new(arrTypeAcc, "size", token), OpType mul, token)

                memcpyCall := FunctionCall new("memcpy", token)
                memcpyCall args add(VariableAccess new(VariableAccess new(varDecl, token), "data", token))
                memcpyCall args add(inner)
                memcpyCall args add(copySize)

                trail addAfterInScope(varDecl, memcpyCall)
            } else {
                if(res fatal) {
                    Exception new(This, "Casting to ArrayType %s in unrecognized parent node %s (%s)!" format(type toString(), parent toString(), parent class name)) throw()
                } else {
                    res wholeAgain(this, "Mysterious parent.")
                }
            }
        }

        // Casting between arrayTypes is always forbidden

        match innerType {
            case arrayType: ArrayType =>
                if (arrayType expr == null) {
                    match type {
                        case arrayType2: ArrayType =>
                            if (arrayType2 expr == null) {
                                msg := "ooc arrays cannot be cast to anything"
                                err := InvalidCast new(token, msg)
                                res throwError(err)
                            }
                    }
                }
        }

        // Casting anything to a generic type (except for Pointer) is disallowed

        if (type isGeneric() && type pointerLevel() == 0) {
            if (!innerType isPointer()) {
                msg := "Only pointers can be cast to generics. '#{inner}' of type '#{innerType}', can't."
                err := InvalidCast new(token, msg)
                res throwError(err)
            }
        }

        // Casting a pointer to a struct is disallowed

        if (groundType isPointer()) {
            typeName := groundType getName()

            // TODO: check whether the "struct " check really works
            // Closure is a special-case (built-in)
            if (typeName == "Closure" || typeName startsWith?("struct ")) {
                msg := "Casting '#{inner}' (a pointer of type #{innerType}) to struct type '#{groundType}' is illegal."
                err := InvalidCast new(token, msg)
                res throwError(err)
            }
        }

        resolved = inner isResolved() && inner getType() && inner getType() isResolved() && type isResolved()

        return Response OK

    }

    isResolved: func -> Bool {
        resolved
    }

    resolveOverload: func (trail: Trail, res: Resolver) -> Response {

        // so here's the plan: we give each operator overload a score
        // depending on how well it fits our requirements (types)

        bestScore := 0
        candidate : OperatorDecl = null

        for(opDecl in trail module() getOperators()) {
            if(opDecl symbol != "as") continue
            score := getScore(opDecl)
            //"Considering %s for %s, score = %d" printfln(opDecl toString(), toString(), score)
            if(score == -1) { res wholeAgain(this, "score of op == -1 !!"); return Response OK }
            if(score > bestScore) {
                bestScore = score
                candidate = opDecl
            }
        }

        for(imp in trail module() getAllImports()) {
            module := imp getModule()
            for(opDecl in module getOperators()) {
                if(opDecl symbol != "as") continue
                score := getScore(opDecl)
                //"Considering %s for %s, score = %d" printfln(opDecl toString(), toString(), score)
                if(score == -1) { res wholeAgain(this, "score of %s == -1 !!"); return Response OK }
                if(score > bestScore) {
                    bestScore = score
                    candidate = opDecl
                }
            }
        }

        if(candidate != null) {
            fDecl := candidate getFunctionDecl()
            fCall := FunctionCall new(fDecl getName(), token)
            fCall getArguments() add(inner)
            fCall setRef(fDecl)
            if(!trail peek() replace(this, fCall)) {
                if(res fatal) res throwError(CouldntReplace new(token, this, fCall, trail))
                res wholeAgain(this, "failed to replace oneself, gotta try again =)")
                return Response OK
            }
            // just replaced with an operator overload
            return Response LOOP
        }

        return Response OK

    }

    getScore: func (op: OperatorDecl) -> Int {

        symbol : String = "as"
        fDecl := op getFunctionDecl()

        args := fDecl getArguments()
        if(args getSize() < 1) {
            token module params errorHandler onError(InvalidCastOverload new(op token,
                "Ohum, you need 1 argument to override the '%s' operator, not %d" format(symbol, args getSize())))
        }

        srcType := args get(0) getType()
        dstType := fDecl getReturnType()

        if(srcType == null || dstType == null || inner getType() == null || type == null) {
            return -1
        }

        srcScore  := inner getType() getScore(srcType)
        if(srcScore < Type SCORE_SEED / 2) srcScore = Type NOLUCK_SCORE
        if(srcScore  == -1) return -1

        dstScore := type getStrictScore(dstType)
        if(dstScore == -1) return -1

        score := srcScore + dstScore

        //if(score > 0) printf("srcScore = %d (%s vs %s), dstScore = %d (%s vs %s)\n",
        //    srcScore, inner getType() toString(), srcType toString(), dstScore, type toString(), dstType toString())

        return score

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case inner => inner = kiddo; true
            case type  => type = kiddo; true
            case => false
        }
    }

    hasSideEffects: func -> Bool { inner hasSideEffects() }

}

/* ROCK ERROR CLASSES */

InvalidCastOverload: class extends Error {

    init: super func ~tokenMessage

}

InvalidCast: class extends Error {

    init: super func ~tokenMessage

}

