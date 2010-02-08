import ../frontend/Token
import ClassDecl, Type
import tinker/[Response, Resolver, Trail]

InterfaceImpl: class extends ClassDecl {
    
    init: func ~interf(.name, .superType, .token) {
        super(name, superType, token)
    }
    
}
