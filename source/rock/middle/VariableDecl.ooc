import structs/[ArrayList]
import Type, Declaration, Expression, Visitor, TypeDecl
import tinker/[Response, Resolver, Trail]

VariableDecl: class extends Declaration {

    name: String
    type: Type
    expr: Expression
    owner: TypeDecl
    
    isStatic := false
    externName: String = null
    
    init: func ~vDecl (.type, .name, .token) {
        this(type, name, null, token)
    }
    
    init: func ~vDeclWithAtom (=type, =name, =expr, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitVariableDecl(this)
    }

    getType: func -> Type { type }
    
    toString: func -> String {
        name + ": " + type toString()
    }
    
    setExpr: func (=expr) {}
    setStatic: func (=isStatic) {}
    
    isExtern: func -> Bool { externName != null }
    
    resolve: func (trail: Trail, res: Response) -> Response {

        trail push(this)
        
        printf("Resolving variable decl %s\n", toString());
        response := type resolve(trail, res)
        if(!response ok()) {
            trail pop(this)
            return response
        }
        
        trail pop(this)
        
        return Responses OK
        
    }

}
