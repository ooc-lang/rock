import ../frontend/Token
import Statement, While, Foreach, Visitor, Node
import tinker/[Trail, Resolver, Response, Errors]

FlowAction: enum {
    _break
    _continue

    toString: func -> String {
        match(this) {
            case This _break     => "break"
            case This _continue  => "continue"
            case                 => "no-op"
        }
    }
}

FlowControl: class extends Statement {
    action : FlowAction

    init: func ~match_ (=action, .token) {
        super(token)
    }

    clone: func -> This {
        new(action, token)
    }

    getAction: func -> FlowAction { action }

    accept: func (visitor: Visitor) {
        visitor visitFlowControl(this)
    }

    replace: func (oldie, kiddo: Node) -> Bool { false }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        // Make sure we are either in a while of foreach statement
        if(trail find(While) == -1 && trail find(Foreach) == -1) {
            res throwError(InvalidFlowControl new(token, "Invalid use of %s outside of a loop" format(action toString())))
        }

        Response OK
    }

    toString: func -> String {
        action toString()
    }
}

InvalidFlowControl: class extends Error {
    init: super func ~tokenMessage
}
