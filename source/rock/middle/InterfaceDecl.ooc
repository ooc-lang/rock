import ../frontend/Token
import tinker/[Response, Resolver, Trail]
import ClassDecl, FunctionDecl, Visitor, CoverDecl, VariableDecl, Type

InterfaceDecl: class extends ClassDecl {
    
    fatType: CoverDecl
    
    init: func ~interfaceDeclNoSuper(.name, .token) {
        super(name, token)
        
        fatType = CoverDecl new(name + "__reference", token)
        fatType addVariable(VariableDecl new(BaseType new("Object", token), "obj", token))
        fatType addVariable(VariableDecl new(getType(), "impl", token))
    }
    
    getInstanceType: func -> Type { fatType getInstanceType() }
    
    accept: func (visitor: Visitor) { visitor visitInterfaceDecl(this) }
    
    addFunction: func (fDecl: FunctionDecl) {
        if(fDecl getBody() isEmpty()) fDecl setAbstract(true)
        super addFunction(fDecl)
    }
    
    getFatType: func -> CoverDecl { fatType }
    
    resolve: func(trail: Trail, res: Resolver) -> Response {
        
        if(!super resolve(trail, res) ok()) return Responses LOOP
        
        return fatType resolve(trail, res)
        
    }
    
}
