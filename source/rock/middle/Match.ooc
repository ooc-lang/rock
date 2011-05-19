import structs/[ArrayList, List]
import ../frontend/Token
import ControlStatement, Statement, Expression, Visitor, VariableDecl,
       Node, VariableAccess, Scope, BoolLiteral, Comparison, Type,
       FunctionDecl, Return, BinaryOp, FunctionCall, Cast, Parenthesis
import tinker/[Trail, Resolver, Response, Errors]

Match: class extends Expression {

    type: Type = null
    expr: Expression = null
    cases := ArrayList<Case> new()

    casesResolved := 0
    casesSize := -1

    init: func ~match_ (.token) {
        super(token)
    }

    clone: func -> This {
        copy := new(token)
        copy expr = expr clone()
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
            current right = Comparison new(expr, current right clone(), CompType equal, caseToken) //replace right node with a com 'expr == right'
            if (!current left instanceOf?(BinaryOp)) { // workaround, otherwise the very left node wouldn't be correctly replaced
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
            response := expr resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        if(casesSize == -1) {
            casesSize = cases getSize()
        }
        
        if(casesResolved < casesSize) {
            for (idx in casesResolved..casesSize) {
                caze := cases[idx]
                if(expr && caze getExpr()) {
                    // When the expr of match is `true` we generate
                    // if(caseExpr) instead of if(true == caseExpr)
                    caseToken := caze getExpr() token
                    if(!(expr instanceOf?(BoolLiteral) && expr as BoolLiteral getValue() == true)) {
                        if(expr getType() ==  null) {
                            res wholeAgain(this, "need expr type")
                            break
                        }
                        caseExpr := caze getExpr()
                        while(caseExpr instanceOf?(Parenthesis))
                            caseExpr = caseExpr as Parenthesis inner
                        if(caseExpr instanceOf?(VariableDecl)) {
                            // unwrap `VariableDecl` (e.g. `case n: Node =>`) cases here
                            fCall: FunctionCall
                            mType := expr getType()
                            if(mType isGeneric()) {
                                acc := VariableAccess new(mType, caseToken)
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
                            first := caze getBody() first()
                            caze addBefore(first, vDecl)
                            // add the Assignment (with a cast, to mute gcc)
                            acc := VariableAccess new(vDecl, caseToken)
                            cast := Cast new(getExpr(), vDecl getType(), caseToken)
                            ass := BinaryOp new(acc, cast, OpType ass, caseToken)
                            caze addBefore(first, ass)
                        } else {
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

    inferType: func (trail: Trail, res: Resolver) -> Response {

        funcIndex   := trail find(FunctionDecl)
        returnIndex := trail find(Return)

        if(funcIndex != -1 && returnIndex != -1) {
            funcDecl := trail get(funcIndex, FunctionDecl)
            if(funcDecl getReturnType() isGeneric()) {
                type = funcDecl getReturnType()
            }
        }

        if(type == null) {
            // TODO make it more intelligent e.g. cycle through all cases and
            // check that all types are compatible and find a common denominator
            if(cases empty?()) {
                return Response OK
            }

            first := cases first()
            if(first getBody() empty?()) {
                return Response OK
            }

            statement := first getBody() last()
            if(!statement instanceOf?(Expression)) {
                return Response OK
            }

            type = statement as Expression getType()
        }

        return Response OK

    }

    getType: func -> Type { type }

    toString: func -> String { class name }

}

Case: class extends ControlStatement {

    expr: Expression

    init: func ~_case (.token) {
        super(token)
    }

    clone: func -> This {
        copy := new(token)
        copy expr = expr clone()
        body list each(|c| copy body add(c clone()))
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
            if(!response ok()) {
                trail pop(this)
                return response
            }
            trail pop(this)
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
