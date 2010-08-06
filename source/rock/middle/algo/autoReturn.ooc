
import ../tinker/[Trail, Resolver, Response]
import ../[Scope, Type, Return, Node, Expression, ControlStatement,
        Conditional, If, Else]

/**
 * Handles implicit return
 *
 * @author Amos Wenger
 */
autoReturn: func (trail: Trail, res: Resolver, origin: Node, body: Scope, returnType: Type) -> Response {

    if(returnType void?) {
        return Responses OK
    }

    _autoReturnExplore(trail, res, origin, body)
    return Responses OK

}

_autoReturnExplore: func (trail: Trail, res: Resolver, origin: Node, scope: Scope) {

    if(scope empty?()) {
        // scope is empty, we need a return
        _returnNeeded(res, origin)
        return
    }

    _handleLastStatement(trail, res, origin, scope, scope lastIndex())

}

_returnNeeded: func (res: Resolver, origin: Node) {
    res throwError(InconsistentReturn new(origin token, "Control reaches the end of non-void function!"))
}

_handleLastStatement: func (trail: Trail, res: Resolver, origin: Node, scope: Scope, index: Int) {

    stmt := scope get(index)

    if(stmt instanceOf?(Return)) {
        // if it's already a return - we're good
        return
    }

    if(stmt instanceOf?(Expression)) {
        expr := stmt as Expression
        if(expr getType() == null) {
            res wholeAgain(origin, "need the type of some statement in autoReturn")
            return
        }

        if(!expr getType() void?) {
            scope set(index, Return new(expr, expr token))
            res wholeAgain(origin, "Replaced last expr with a Return")
        }
    } else if(stmt instanceOf?(ControlStatement)) {
        cStat := stmt as ControlStatement
        if(cStat isDeadEnd()) {
            _autoReturnExplore(trail, res, origin, cStat getBody())

            // TODO: this doesn't work with long if-else chains
            if(cStat instanceOf?(Else) && index > 0 && scope get(index - 1) instanceOf?(Conditional)) {
                // if we're in an else, go back in the Scope to find an if and handle it too
                _handleLastStatement(trail, res, origin, scope, index - 1)
            }
        } else {
            _returnNeeded(res, origin)
        }
    } else {
        // unknown type of node? need return.

        _returnNeeded(res, origin)
        res wholeAgain(origin, "was needing return")
        return
    }

}

