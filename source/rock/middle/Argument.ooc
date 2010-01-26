import ../frontend/Token
import VariableDecl, Type, Visitor, Node
import tinker/[Trail, Resolver, Response]

Argument: abstract class extends VariableDecl {
    
    init: func ~argument (.type, .name, .token) { super(type, name, token) }
    
}

VarArg: class extends Argument {
    
    init: func ~varArg (.token) { super(null, "<...>", token) }
    
    accept: func (visitor: Visitor) {
        visitor visitVarArg(this)
    }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
    isResolved: func -> Bool { true }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        return Responses OK
    }
    
}
