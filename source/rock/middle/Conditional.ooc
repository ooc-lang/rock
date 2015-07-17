import ../frontend/Token
import ControlStatement, Expression, Node
import tinker/[Trail, Resolver, Response]

Conditional: abstract class extends ControlStatement {

    _resolved := false

    condition: Expression

    init: func ~conditional (=condition, .token) { super(token) }

    resolveCondition: func (trail: Trail, res: Resolver) -> BranchResult {
        trail push(this)
        result := condition resolve(trail, res)
        trail pop(this)

        if (result == Response LOOP) {
            return BranchResult LOOP
        }

        if (!condition isResolved()) {
            res wholeAgain(this, "waiting on condition to resolve")
            return BranchResult BREAK
        }

        BranchResult CONTINUE
    }

    refresh: func {
        _resolved = false
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        if(oldie == condition) {
            condition = kiddo
            refresh()
            return true
        }

        return super(oldie, kiddo)
    }

    isDeadEnd: func -> Bool { true }

}
