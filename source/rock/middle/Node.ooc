import Visitor, FunctionCall, VariableAccess, Type
import ../frontend/Token
import tinker/[Resolver, Response, Trail]

Node: abstract class {

    nameSeed: static Int = 0

    token: Token
    
    init: func(=token) {}
    
    accept: abstract func (visitor: Visitor)
    
    toString: func -> String { class name }

    isResolved: func -> Bool { true }

    resolve: func (trail: Trail, res: Resolver) -> Response { return Responses OK }
    
    replace: abstract func (oldie, kiddo: Node) -> Bool
    
    addBefore: func (mark, newcomer: Node) -> Bool { false }
    addAfter:  func (mark, newcomer: Node) -> Bool { true }
    
    isScope: func -> Bool { false }
    
    /**
     * resolveCall should look for a function declaration satisfying call,
     * and suggest it with call suggest(fDecl)
     */
    resolveCall: func (call : FunctionCall) {
        // overridden in sub-classes
    }
    
    resolveAccess: func (access: VariableAccess) {
        // overridden in sub-classes
    }
    
    resolveType: func (type: BaseType) {
        // overridden in sub-classes
    }
    
    generateTempName: func (origin: String) -> String {
        nameSeed += 1
        return origin + nameSeed
    }

}
