import ../frontend/Token
import Statement, Visitor, Node
import tinker/[Trail, Resolver, Response]

FlowAction: enum {
    _break
    _continue
}

extend FlowAction {
    toString: func -> String {
        match(this) {
            case _break     => "break"
            case _continue  => "continue"
            case            => "no-op"
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
        Response OK
    }
}
