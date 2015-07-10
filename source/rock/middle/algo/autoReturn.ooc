
import ../tinker/[Trail, Resolver, Response]
import ../[Scope, Type, Return, Node, Expression, ControlStatement,
        Conditional, If, Else]

/**
 * Handles implicit return
 */
autoReturn: func (trail: Trail, res: Resolver, origin: Node, body: Scope, returnType: Type) -> Response {

    if(returnType void?) {
        return Response OK
    }

    _autoReturnExplore(trail, res, origin, body, true)
    return Response OK

}

_autoReturnExplore: func (trail: Trail, res: Resolver, origin: Node, scope: Scope, last: Bool) {

    if(scope empty?()) {
        // scope is empty, we need a return
        origin token printMessage("scope is empty #{scope}")
        _returnNeeded(res, origin)
        return
    }

    _handleLastStatement(trail, res, origin, scope, scope lastIndex(), last)

}

_returnNeeded: func (res: Resolver, origin: Node) {
    res throwError(InconsistentReturn new(origin token, "Control reaches the end of non-void function! (hint: maybe return statement is missing?)"))
}

_handleLastStatement: func (trail: Trail, res: Resolver, origin: Node, scope: Scope, index: Int, last: Bool) {

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
            expr refresh()
            res wholeAgain(origin, "Replaced last expr with a Return")
        }
    } else if(stmt instanceOf?(ControlStatement)) {
        cStat := stmt as ControlStatement
        if(cStat isDeadEnd()) {
            _autoReturnExplore(trail, res, origin, cStat getBody(), true)

            if(cStat instanceOf?(Else)) {
                currentIndex := index - 1
                // handle if-else chains. If an if-else chain is the last statement, they all need
                // to be considered as dead-ends. We explore every if/else from the bottom up
                while(currentIndex >= 0 && scope get(currentIndex) instanceOf?(Conditional)) {
                    prevStatement := scope get(currentIndex)
                    if(prevStatement instanceOf?(Else)) {
                        prevElse := prevStatement as Else
                        if(prevElse getBody() getSize() == 1 && prevElse getBody() get(0) instanceOf?(If)) {
                            ifBody := prevElse getBody() get(0) as If getBody()
                            _handleLastStatement(trail, res, origin, ifBody, ifBody lastIndex(), true)

                            currentIndex -= 1
                            continue
                        }
                    } else if(prevStatement instanceOf?(If)) {
                        // an if is the upper end of an if-else chain
                        ifBody := prevStatement as If getBody()
                        _handleLastStatement(trail, res, origin, ifBody, ifBody lastIndex(), true)
                    }
                    break
                }
            }
        } else {
            origin token printMessage("cStat #{cStat class name} isn't dead end #{cStat}")
            _returnNeeded(res, origin)
        }
    } else {
        // unknown type of node? need return.
        origin token printMessage("unknown type for stmt #{stmt}")

        _returnNeeded(res, origin)
        res wholeAgain(origin, "was needing return")
        return
    }

}

