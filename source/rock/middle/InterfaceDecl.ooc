import ../frontend/Token
import tinker/[Response, Resolver, Trail]
import ClassDecl, FunctionDecl, Visitor

InterfaceDecl: class extends ClassDecl {
    
    init: func ~interfaceDeclNoSuper(.name, .token) {
        super(name, token)
    }
    
    accept: func (visitor: Visitor) { visitor visitInterfaceDecl(this) }
    
    addFunction: func (fDecl: FunctionDecl) {
        if(fDecl getBody() isEmpty()) fDecl setAbstract(true)
        super addFunction(fDecl)
    }
    
}
