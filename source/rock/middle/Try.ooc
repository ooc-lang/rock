import structs/[ArrayList, List]
import ../frontend/Token
import ControlStatement, Statement, Expression, Visitor, VariableDecl,
       Node, VariableAccess, Scope, BoolLiteral, Comparison, Type,
       FunctionDecl, Return, BinaryOp, FunctionCall, Cast, Block, Match,
       Comparison, IntLiteral, If, Else, Dereference
import tinker/[Trail, Resolver, Response, Errors]

Try: class extends ControlStatement {

    catches := ArrayList<Case> new()

    init: func ~try_ (.token) {
        super(token)
    }

    clone: func -> This {
        copy := new(token)
        catches each(|c| copy catches add(c clone()))
        copy
    }

    getCatches: func -> List<Case> { catches }

    addCatch: func (caze: Case) {
        catches add(caze)
    }

    accept: func (visitor: Visitor) {
        Exception new(This, "This should not happen") throw()
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        false
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        // replace myself with some code.
        // let's create a block.
        block := Block new(token)
        // let's add the jmp stuff.
        // __frame__ = _pushStackFrame()
        frame := VariableDecl new(null, "__frame__",
                    FunctionCall new("_pushStackFrame", token),
                    token)
        block add(frame)
        // if(__frame__@ buf setJmp() == 0) { ... }
        if_ := If new(
                    Comparison new(
                        FunctionCall new(
                            VariableAccess new(
                                Dereference new(
                                    VariableAccess new(frame, token),
                                    token
                                ),
                                "buf",
                                token
                            ),
                            "setJmp",
                            token
                        ),
                        IntLiteral new(0, token),
                        CompType equal,
                        token
                    ),
                    token)
        block add(if_)
        if_ getBody() addAll(this getBody())

        // if everything went fine, unregister the exception handler
        if_ getBody() add(FunctionCall new("_popStackFrame", token))

        // else {
        else_ := Else new(token)
        if_ setElse(else_)
        // match (_getException()) { ... }
        match_ := Match new(token)
        match_ setExpr(FunctionCall new("_getException", token))
        match_ cases addAll(catches)
        else_ add(match_)
        // add the last "fall-through" case if needed.
        rethrow? := true
        for(caze in catches) {
            if(caze getExpr() == null) {
                rethrow? = false
                break
            }
        }
        if(rethrow?) {
            caze := Case new(token)
            // _getException() rethrow()
            caze add(FunctionCall new(FunctionCall new("_getException", token), "rethrow", token))
            match_ addCase(caze)
        }
        // }
        result := trail peek() replace(this, block)
        if(!result) {
            res throwError(CouldntReplace new(token, this, block, trail))
            return Response LOOP
        }
        res wholeAgain(this, "Just unwrapped.")
        return Response LOOP
    }

    toString: func -> String { class name }

}
