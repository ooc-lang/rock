import structs/ArrayList
import ../frontend/Token
import Expression, Type, Visitor, TypeDecl, Node
import tinker/[Response, Resolver, Trail]

CoverDecl: class extends TypeDecl {
    
    fromType: Type
    
    init: func ~coverDecl(.name, .superType, .token) {
        super(name, superType, token)
        //printf("Got CoverDecl %s\n", name)
    }
    
    accept: func (visitor: Visitor) { visitor visitCoverDecl(this) }
    
    setFromType: func (=fromType) {
        //printf("CoverDecl %s is now from type %s\n", name, fromType toString())
    }
    
    isAddon: func -> Bool { false }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        {
            response := super resolve(trail, res)
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
