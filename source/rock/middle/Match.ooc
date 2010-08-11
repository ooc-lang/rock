import structs/[ArrayList, List]
import ../frontend/Token
import ControlStatement, Statement, Expression, Visitor, VariableDecl,
       Node, VariableAccess, Scope, BoolLiteral, Comparison, Type,
       FunctionDecl, Return, BinaryOp, FunctionCall
import tinker/[Trail, Resolver, Response, Errors]

Match: class extends Expression {

    type: Type = null
    expr: Expression = null
    cases := ArrayList<Case> new()

    casesResolved? := false

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

    resolve: func (trail: Trail, res: Resolver) -> Response {
        if (expr != null) {
            response := expr resolve(trail, res)
            if(!response ok()) return response
        }

        trail push(this)
        if(!casesResolved?) {
            casesResolved? = true
            for (caze in cases) {
                if(expr && caze getExpr()) {
                    // When the expr of match is `true` we generate
                    // if(caseExpr) instead of if(true == caseExpr)
                    if(!(expr instanceOf?(BoolLiteral) && expr as BoolLiteral getValue() == true)) {
                        if(expr getType() ==  null) {
                            res wholeAgain(this, "need expr type")
                            casesResolved? = false
                            break
                        }
                        fCall := FunctionCall new(expr, "matches__quest", caze getExpr() token)
                        fCall args add(caze getExpr())
                        hmm := fCall resolve(trail, res)
                        if(fCall getRef() != null) {
                            returnType := fCall getRef() getReturnType() getName()
                            if(returnType != "Bool")
                                res throwError(WrongMatchesSignature new(expr token, "matches? returns a %s, but it should return a Bool" format(returnType)))
                            caze setExpr(fCall)
                        } else {
                            caze setExpr(Comparison new(expr, caze getExpr(), CompType equal, caze getExpr() token))
                        }
                    }
                }
            }
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
                return Responses OK
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
                    last := caze getBody() last()
                    if(!last instanceOf?(Expression)) {
                        res throwError(ExpectedExpression new(last token, "Last statement of a match used an expression should be an expression itself!"))
                    }
                    ass := BinaryOp new(varAcc, last as Expression, OpType ass, caze token)
                    caze getBody() set(caze getBody() lastIndex(), ass)
                }
                res wholeAgain(this, "just unwrapped")
                return Responses OK
            }
        }

        return Responses OK

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
                return Responses OK
            }

            first := cases first()
            if(first getBody() empty?()) {
                return Responses OK
            }

            statement := first getBody() last()
            if(!statement instanceOf?(Expression)) {
                return Responses OK
            }

            type = statement as Expression getType()
        }

        return Responses OK

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
