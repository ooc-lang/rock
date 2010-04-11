import Visitor, FunctionCall, VariableAccess, VariableDecl, Type, BaseType
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
    addAfter:  func (mark, newcomer: Node) -> Bool { false }
    
    isScope: func -> Bool { false }
    
    getRequiredType: func -> Type { null }
    
    /**
     * resolveCall should look for a function declaration satisfying call,
     * and suggest it with call suggest(fDecl)
     * 
     * :return: -1 if unresolved types prevented the call resolving
     * process from finishing, and it should be repeated later, any
     * other value else.
     */
    resolveCall: func (call : FunctionCall) -> Int {
        // overridden in sub-classes
        0
    }
    
    resolveAccess: func (access: VariableAccess) {
        // overridden in sub-classes
    }
    
    resolveType: func (type: BaseType) {
        // overridden in sub-classes
    }
    
    /**
     * :return: true if the node supports type arguments and it's been
     * successfully added, false if not
     */
    addTypeArg: func (typeArg: VariableDecl) -> Bool { false }
    
    generateTempName: func (origin: String) -> String {
        This nameSeed += 1
        return "__" + origin + This nameSeed
    }

}
