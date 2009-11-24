import structs/ArrayList
import ../frontend/Token
import Expression, Line, Type, Visitor, Argument, TypeDecl, Scope, VariableAccess
import tinker/[Resolver, Response, Trail]

FunctionDecl: class extends Expression {

    name = "", suffix = null : String
    returnType := voidType
    type: static Type = BaseType new("Func", nullToken)
    
    /** Attributes */
    isAbstract := false
    isStatic := false
    isInline := false
    isFinal := false
    externName : String = null
    
    args := ArrayList<Argument> new()
    body := Scope new()
    
    owner : TypeDecl = null

    init: func ~funcDecl (=name, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) { visitor visitFunctionDecl(this) }
    
    hasReturn: func -> Bool {
        // TODO add Generic support
        //return !getReturnType().isVoid() && !(getReturnType().getRef() instanceof TypeParam);
        returnType != voidType
    }
    
    hasThis:  func -> Bool { isMember() && !isStatic }
    isMember: func -> Bool { owner != null }
    isExtern: func -> Bool { externName != null }
    
    getType: func -> Type { type }
    
    toString: func -> String {
        name + ": func"
    }
    
    isResolved: func -> Bool { false }
    
    resolveAccess: func (access: VariableAccess) {
        body resolveAccess(access)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        
        printf("Resolving function decl %s (returnType = %s)\n", toString(), returnType toString())

        {
            response := returnType resolve(trail, res)
            printf("Response of return type %s = %s\n", returnType toString(), response toString())
            if(!response ok()) return response
        }

        for(arg in args) {
            response := arg resolve(trail, res)
            printf("Response of arg %s = %s\n", arg toString(), response toString())
            if(!response ok()) return response
        }
        
        for(line in body) {
            response := line inner resolve(trail, res)
            printf("Response of line inner [%s] %s = %s\n", line inner class name, line inner toString(), response toString())
            if(!response ok()) return response
        }
        
        trail pop(this)
        
        return Responses OK
        
    }
    
}
