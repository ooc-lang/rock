import structs/ArrayList
import ../frontend/Token
import Statement, Visitor, Node
import tinker/[Trail, Resolver, Response]
include stdint

FlowAction: cover from Int8 {

    toString: func -> String {
        FlowActions repr get(this)
    }
    
}

FlowActions: class {
    _break    = 1,
    _continue = 2 : static const FlowAction
    
    repr := static ["no-op",
        "break",
        "continue"] as ArrayList<String>
}

FlowControl: class extends Statement {
    
    action : FlowAction

    init: func ~match_ (=action, .token) {
        super(token)
    }
    
    getAction: func -> FlowAction { action }
    
    accept: func (visitor: Visitor) {
        visitor visitFlowControl(this)
    }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        return Responses OK
    }
    
}
