import structs/ArrayList
import ../frontend/Token
import Expression, Line, Type, Visitor, Argument, TypeDecl
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
    body := ArrayList<Line> new()
    
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
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        
        printf("Resolving function decl %s (returnType = %s)\n", toString(), returnType toString())

        {
            response := returnType resolve(trail, res)
            if(!response ok()) return response
        }

        for(arg in args) {
            response := arg resolve(trail, res)
            if(!response ok()) return response
        }
        
        for(line in body) {
            //printf("Resolving line, inner = %s\n", line inner toString())
            response := line inner resolve(trail, res)
            if(!response ok()) return response
        }
        
        trail pop(this)
        
        return Responses OK
        
    }
    
}
