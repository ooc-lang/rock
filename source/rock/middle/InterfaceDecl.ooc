import ../frontend/Token
import tinker/[Response, Resolver, Trail]
import ClassDecl, FunctionDecl, Visitor, CoverDecl, VariableDecl, Type

InterfaceDecl: class extends ClassDecl {
    
    fatType: CoverDecl
    
    init: func ~interfaceDeclNoSuper(.name, .token) {
        super(name, token)
        
        fatType = CoverDecl new(name + "__reference", token)
        // "If you're gonna crash, do it as soon and as noisily as possible"
        // declaring 'obj' first would hide a bug with calls to interface functions
        // that have at least one argument.
        // Done this way, it will only work if "this.obj" is passed, not "this" with
        // incorrect function prototypes
        fatType addVariable(VariableDecl new(getType(), "impl", token))
        fatType addVariable(VariableDecl new(BaseType new("Object", token), "obj", token))
    }
    
    getInstanceType: func -> Type { fatType getInstanceType() }
    
    accept: func (visitor: Visitor) { visitor visitInterfaceDecl(this) }
    
    addFunction: func (fDecl: FunctionDecl) {
        if(fDecl getBody() isEmpty()) fDecl setAbstract(true)
        super(fDecl)
    }
    
    getFatType: func -> CoverDecl { fatType }
    
    resolve: func(trail: Trail, res: Resolver) -> Response {
        
        if(!super(trail, res) ok()) return Responses LOOP
        
        return fatType resolve(trail, res)
        
    }
    
}
