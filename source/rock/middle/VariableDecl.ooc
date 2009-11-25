import structs/[ArrayList]
import Type, Declaration, Expression, Visitor, TypeDecl, VariableAccess
import tinker/[Response, Resolver, Trail]

VariableDecl: class extends Declaration {

    name: String
    type: Type
    expr: Expression
    owner: TypeDecl
    
    isConst := false
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
        if(!type) return name + ": <unknown type>"
        name + ": " + type toString()
    }
    
    setExpr: func (=expr) {}
    setStatic: func (=isStatic) {}
    
    isExtern: func -> Bool { externName != null }
    
    resolveAccess: func (access: VariableAccess) {
        if(name == access name) {
            access suggest(this)
        }
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)

        //printf("Resolving variable decl %s\n", toString());
        
        if(expr) {
            response := expr resolve(trail, res)
            //printf("response of expr = %s\n", response toString())
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        if(!type) {
            //"coool! we're gonna have to infer it!" println()
            type = expr getType()
            if(!type) {
                //"Still null, looping..." println()
                return Responses LOOP
            }
        }
        
        {
            response := type resolve(trail, res)
            //printf("response of type = %s\n", response toString())
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        trail pop(this)
        
        return Responses OK
        
    }

}
