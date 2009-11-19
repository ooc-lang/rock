import Visitor
import ../frontend/Token
import tinker/[Resolver, Response, Trail]

Node: abstract class {

    token: Token
    
    init: func(=token) {}
    
    accept: abstract func (visitor: Visitor)
    
    toString: func -> String { class name }

    isResolved: func -> Bool { true }

    resolve: func (trail: Trail, res: Resolver) -> Response { return Responses OK }

}
