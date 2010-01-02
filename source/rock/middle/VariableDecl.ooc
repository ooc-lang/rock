import structs/[ArrayList]
import Type, Declaration, Expression, Visitor, TypeDecl, VariableAccess,
       Node, ClassDecl
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
    
    getName: func -> String { name }
    
    toString: func -> String {
        "%s : %s%s" format(
            name,
            type ? type toString() : "<unknown type>",
            expr ? " = " + expr toString() : ""
        )
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
        
        {
            parent := trail peek()
            if(!parent isScope() && !parent instanceOf(ClassDecl)) {
                println("uh oh the parent of " + toString() + " isn't a scope but a " + parent class name)
                idx := trail findScope()
                result := trail get(idx) addBefore(trail get(idx + 1), this)
                trail peek() replace(this, VariableAccess new(this, token))
            } 
        }
        
        return Responses OK
        
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo; true
            case type => type = kiddo; true
            case => false
        }
    }

}
