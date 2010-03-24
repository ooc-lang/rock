import structs/ArrayList
import ../frontend/Token
import Expression, Type, Visitor, TypeDecl, Node, FunctionDecl
import tinker/[Response, Resolver, Trail]

CoverDecl: class extends TypeDecl {
    
    fromType: Type
    
    init: func ~coverDeclNoSuper(.name, .token) {
        init(name, null, token)
    }
    
    init: func ~coverDecl(.name, .superType, .token) {
        super(name, superType, token)
    }
    
    accept: func (visitor: Visitor) { visitor visitCoverDecl(this) }
    
    setFromType: func (=fromType) {}    
    getFromType: func -> Type { fromType }
    
    // all functions of a cover are final, because we don't have a 'class' field
    addFunction: func (fDecl: FunctionDecl) {
        fDecl isFinal = true
        super(fDecl)
    }
    
    isAddon: func -> Bool { false }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        {
            response := super(trail, res)
            if(!response ok()) return response
        }
        
        trail push(this)
        
        if(fromType) {
            response := fromType resolve(trail, res)
            if(!response ok()) {
                //printf("Giving up on cover type %s\n", fromType toString())
                fromType setRef(BuiltinType new(fromType toString(), nullToken))
            }
        }
        
        trail pop(this)
        
        return Responses OK
    }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
}
