import structs/[ArrayList, List]
import ../frontend/Token
import algo/typeAnalysis
import ControlStatement, Statement, Expression, Visitor, VariableDecl,
       Node, VariableAccess, Scope, BoolLiteral, Comparison, Type,
       FunctionDecl, Return, BinaryOp, FunctionCall, Cast, Parenthesis,
       CoverDecl, If, Conditional
import tinker/[Trail, Resolver, Response, Errors]

Match: class extends Expression {

    type: Type = null
    expr: Expression = null
    cases := ArrayList<Case> new()

    unwrappedExpr := false

    casesResolved := 0
    casesSize := -1

    _statementCalculated? := false
    _statement?: Bool

    init: func ~match_ (.token) {
        super(token)
    }

    clone: func -> This {
        copy := new(token)
        if (expr) {
            copy expr = expr clone()
        }
        cases each(|c| copy cases add(c clone()))
        copy
    }

    getExpr: func -> Expression { expr }
    setExpr: func (=expr) {}

    getCases: func -> List<Case> { cases }

    addCase: func (caze: Case) {
        cases add(caze)
    }

    accept: func (visitor: Visitor) {
        visitor visitMatch(this)
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo; true
            case      => false
        }
    }

    unwrapBinaryOpCase: func(caze: Case) {
        head := caze getExpr() clone() as BinaryOp
        current := head // our pointer
        caseToken := caze getExpr() token
        while (current instanceOf?(BinaryOp) && (current type == OpType and || current type == OpType or)) {
            // replace right node with a com 'expr == right'
            current right = Comparison new(expr, current right clone(), CompType equal, caseToken)

            // workaround, otherwise the very left node wouldn't be correctly replaced
            if (!current left instanceOf?(BinaryOp)) {
                current left = Comparison new(expr, current left clone(), CompType equal, caseToken)
                break
            }
            current = current left
        }
        caze setExpr(head)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        trail push(this)

        if (expr != null) {
            running := true
            while (running) {
                match expr {
                    case p: Parenthesis =>
                        expr = p inner
                    case =>
                        running = false
                }
            }

            response := expr resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }

            if (!unwrappedExpr) {
                match expr {
                    case vd: VariableDecl =>
                        // vds unwrap themselves, no need to do it here
                        unwrappedExpr = true
                    case va: VariableAccess =>
                        // all good
                        unwrappedExpr = true
                    case =>
                        // To avoid evaluating the match expression more than once, we
                        // unwrap it into a prior variable declaration - just for safety.
                        // As is, this code might unwrap more than necessary (e.g. a literal)
                        // We need a better way to determine whether an expression will have
                        // side effects when evaluating, but that's beyond the scope of
                        // that issue: https://github.com/nddrylliog/rock/issues/615
                        vdfe := VariableDecl new(null, generateTempName("matchExpr"), expr, expr token)
                        if (trail addBeforeInScope(this, vdfe)) {
                            expr = VariableAccess new(vdfe, vdfe token)
                            unwrappedExpr = true
                        } else {
                            if (res fatal) {
                                res throwError(CouldntAddBeforeInScope new(token, this, vdfe, trail))
                            }
                            res wholeAgain(this, "need to unwrap expr")
                            return Response OK
                        }
                }
            }
        }

        if(casesSize == -1) {
            casesSize = cases getSize()
        }

        catchAll? := false

        if(casesResolved < casesSize) {
            for (idx in casesResolved..casesSize) {
                caze := cases[idx]
                caseExpr := caze getExpr()
                if(expr && caseExpr) {
                    // When the expr of match is `true` we generate
                    // if(caseExpr) instead of if(true == caseExpr)
                    caseToken := caseExpr token
                    if(!(expr instanceOf?(BoolLiteral) && expr as BoolLiteral getValue() == true)) {
                        if(expr getType() ==  null) {
                            res wholeAgain(this, "need expr type")
                            break
                        }

                        while(caseExpr instanceOf?(Parenthesis)) {
                            caseExpr = caseExpr as Parenthesis inner
                        }

                        if(caseExpr instanceOf?(VariableDecl)) {
                            // unwrap `VariableDecl` (e.g. `case n: Node =>`) cases here
                            fCall: FunctionCall
                            mType := expr getType()
                            ref := mType getRef()

                            if(mType isGeneric()) {
                                acc := VariableAccess new(mType, caseToken)
                                fCall = FunctionCall new(acc, "inheritsFrom__quest", caseToken)
                            } else if(ref instanceOf?(CoverDecl)) {
                                acc := VariableAccess new(expr, "class", expr token)
                                fCall = FunctionCall new(acc, "inheritsFrom__quest", caseToken)
                            } else {
                                fCall = FunctionCall new(expr, "instanceOf__quest", caseToken)
                            }
                            fCall args add(TypeAccess new(caseExpr getType(), caseToken))
                            hmm := fCall resolve(trail, res)
                            vDecl := caseExpr as VariableDecl
                            if(fCall getRef() == null) {
                                if(res fatal) {
                                    res throwError(
                                        CantUseMatch new(expr token,
                                            "You can't use the type match syntax here, can't resolve `%s`" format(fCall toString())
                                    ))
                                } else {
                                    res wholeAgain(this, "call can't be resolved, let's forget it")
                                    break
                                }
                            } else {
                                caze setExpr(fCall)
                            }
                            // inject the variable
                            // add the vDecl
                            caze addFirst(vDecl)

                            // add the Assignment (with a cast, to mute gcc)
                            acc := VariableAccess new(vDecl, caseToken)
                            cast := Cast new(getExpr(), vDecl getType(), caseToken)
                            ass := BinaryOp new(acc, cast, OpType ass, caseToken)
                            caze addAfter(vDecl, ass)
                        } else {
                            // try to use 'matches?' but only if we're not in the fatal round,
                            // otherwise we'll get misleading errors.
                            if (!res fatal) {
                                fCall := FunctionCall new(expr, "matches__quest", caseToken)
                                fCall args add(caze getExpr())

                                hmm := fCall resolve(trail, res)
                                if(fCall getRef() != null) {
                                    returnType := fCall getRef() getReturnType() getName()
                                    if(returnType != "Bool")
                                        res throwError(WrongMatchesSignature new(expr token, "matches? returns a %s, but it should return a Bool" format(returnType)))
                                    caze setExpr(fCall)
                                } else {
                                    if (caze getExpr() instanceOf?(BinaryOp)) {
                                        unwrapBinaryOpCase(caze)
                                    } else {
                                        caze setExpr(Comparison new(expr, caze getExpr(), CompType equal, caseToken))
                                    }
                                }
                            }
                        }
                    }
                } else if(!caseExpr) {
                    // This is a catch-all!
                    if(catchAll?) {
                        res throwError(MultipleCatchAll new(caze token, "Multiple catch-all cases detected, only the first one has any effect"))
                    } else catchAll? = true
                }
                casesResolved += 1
            }
        }
        if(casesResolved < casesSize) {
            trail pop(this)
            return Response OK
        }

        for (caze in cases) {
            response := caze resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)

        if(type == null) {
            response := inferType(trail, res)
            if(!response ok()) {
                return response
            }
            if(type == null && !(trail peek() instanceOf?(Scope))) {
                if(res fatal) res throwError(InternalError new(token, "Couldn't figure out type of match"))
                res wholeAgain(this, "need to resolve type")
                return Response OK
            }
        }

        if(!trail peek() instanceOf?(Scope)) {
            if(type != null) {
                vDecl := VariableDecl new(type, generateTempName("match"), token)
                varAcc := VariableAccess new(vDecl, token)
                parent := trail peek() as Statement
                if(!trail addBeforeInScope(parent, vDecl)) {
                    res throwError(CouldntAddBeforeInScope new(token, parent, vDecl, trail))
                }
                if(!trail addBeforeInScope(parent, this)) {
                    res throwError(CouldntAddBeforeInScope new(token, parent, this, trail))
                }
                if(!parent replace(this, varAcc)) {
                    res throwError(CouldntReplace new(token, this, varAcc, trail))
                }
                for(caze in cases) {
                    if(caze getBody() empty?()) {
                        res throwError(ExpectedExpression new(caze token, "Cases in a Match used an expression should be expressions themselves!"))
                    } else {
                        last := caze getBody() last()
                        if(!last instanceOf?(Expression)) {
                            res throwError(ExpectedExpression new(last token, "Last statement of a match used an expression should be an expression itself!"))
                        }
                        ass := BinaryOp new(varAcc, last as Expression, OpType ass, caze token)
                        caze getBody() set(caze getBody() lastIndex(), ass)
                    }
                }
                res wholeAgain(this, "just unwrapped")
                return Response OK
            }
        }

        return Response OK

    }

    isStatement: func(trail: Trail, depth := 0) -> Bool {
        // If the match is not in a scope, it is definitely an expression, not a statement.
        // Otherwise, there are three cases where it can be an expression.
        // 1) If it is the last statement in a non-void return FunctionDecl scope
        // 2) If it is the last statement in a Conditionals' scope, when this conditional is part of a conditional branch
        //    that is the only thing in a non-void FunctionDecl scope
        // 3) If it is the last statement in a Case's scope, where the Match statement of the Case is an expression itself

        calc := func(b: Bool) -> Bool {
            _statementCalculated? = true
            _statement? = b
            b
        }

        if(_statementCalculated?) {
            return _statement?
        }

        diff := trail getSize() - depth
        if(trail find(Scope, diff - 1) != diff - 1) {
            return calc(false)
        }


        if(diff < 2) return calc(true)
        scopeParent := trail get(diff - 2)
        match scopeParent {
            case fDecl: FunctionDecl => return fDecl body last() != this || fDecl returnType == voidType
            case cond: Conditional => {
                // An If-Else as the only two statements in a function decl body is an expression
                if(cond body last() != this) return calc(true)

                if(diff < 4) return calc(true)
                fDecl? := trail get(diff - 4)
                if(!fDecl? instanceOf?(FunctionDecl)) return calc(true)

                fDecl := fDecl? as FunctionDecl
                // The fDecl needs at least 2 statements to have an If-Else statement :D
                if(fDecl body getSize() < 2 || fDecl returnType == voidType) return calc(true)

                if(!fDecl body first() instanceOf?(If)) return calc(true)
                for(i in 1 .. fDecl body getSize() - 1) {
                    if(!fDecl body get(i) instanceOf?(Conditional)) return calc(true)
                }

                return calc(false)
            }
            case m: Match => {
                // The case pops itself from the trail before resolving the body, so we get the match directly!
                return calc(m isStatement(trail, depth + 2))
            }
        }

        calc(true)
    }

    inferType: func (trail: Trail, res: Resolver) -> Response {

        funcIndex   := trail find(FunctionDecl)
        returnIndex := trail find(Return)

        if(funcIndex != -1 && returnIndex != -1) {
            funcDecl := trail get(funcIndex, FunctionDecl)
            if(funcDecl getReturnType() isGeneric()) {
                type = funcDecl getReturnType()
            }
        }

        if(!type) {
            if(cases empty?()) {
                return Response OK
            }

            baseType := cases first() getType()
            if(!baseType) return Response OK

            // If the match is a statement rather than an expression, we don't need to find a common type
            // In fact, it is harmful to do so as incompatible "return" types from each case are allowed
            if(isStatement(trail)) {
                type = baseType
                return Response OK
            }

            // We find the common roots between our base type and next type
            // This root becomes our new base type
            // If there is no root, this means we have an incompatible type
            for(i in 1 .. cases getSize()) {
                currType := cases get(i) getType()
                if(!currType) return Response OK

                root := findCommonRoot(baseType, currType)
                if(!root) {
                    if(res fatal) {
                        res throwError(IncompatibleType new(cases get(i) token,\
                            "Type %s is incompatible with the inferred type of match %s" format(currType toString(), baseType toString())))
                    } else {
                        res wholeAgain(this, "needs resolved ref for all types")
                    }
                    return Response OK
                }

                baseType = root
            }
            type = baseType
        }

        return Response OK

    }

    getType: func -> Type { type }

    toString: func -> String {
        match expr {
            case null => "match ()"
            case => "match (%s)" format(expr toString())
        }
    }

}

Case: class extends ControlStatement {

    expr: Expression

    init: func ~_case (.token) {
        super(token)
    }

    clone: func -> This {
        copy := new(token)
        copy expr = expr ? expr clone() : null
        body list each(|c|
            copy body add(c clone())
        )
        copy
    }

    accept: func (visitor: Visitor) {}

    getExpr: func -> Expression { expr }
    setExpr: func (=expr) {}

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) {

        // FIXME: probably not necessary (harmful, even)
        body resolveAccess(access, res, trail)

    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if (expr != null) {
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                return response
            }
        }

        return body resolve(trail, res)

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        if(oldie == expr) {
            expr = kiddo as Expression
            return true
        }
        false
    }

    getType: func -> Type {
        body := getBody()
        if(body empty?()) return null

        statement := body last()
        if(!statement instanceOf?(Expression)) {
            return null
        }

        return statement as Expression getType()
    }
}

ExpectedExpression: class extends Error {
    init: super func ~tokenMessage
}

WrongMatchesSignature: class extends Error {
    init: super func ~tokenMessage
}

CantUseMatch: class extends Error {
    init: super func ~tokenMessage
}

IncompatibleType: class extends Error {
    init: super func ~tokenMessage
}

MultipleCatchAll: class extends Warning {
    init: super func ~tokenMessage
}
