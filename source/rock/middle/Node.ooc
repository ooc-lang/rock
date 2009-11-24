import Visitor, FunctionCall
import ../frontend/Token
import tinker/[Resolver, Response, Trail]

Node: abstract class {

    token: Token
    
    init: func(=token) {}
    
    accept: abstract func (visitor: Visitor)
    
    toString: func -> String { class name }

    isResolved: func -> Bool { true }

    resolve: func (trail: Trail, res: Resolver) -> Response { return Responses OK }
    
    /**
     * resolveCall should look for a function declaration satisfying call,
     * and suggest it with call suggest(fDecl)
     */
    resolveCall: func (call : FunctionCall) {
        // well, in the general case, we don't know how to resolve a function, so..
    }

}
