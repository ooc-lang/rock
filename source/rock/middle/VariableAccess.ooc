import ../frontend/Token
import Visitor, Expression, VariableDecl, Declaration, Type
import tinker/[Resolver, Response, Trail]

VariableAccess: class extends Expression {

    expr: Expression
    name: String
    
    ref: Declaration
    
    init: func ~variableAccess (.name, .token) {
        this(null, name, token)
    }
    
    init: func ~variableAccessWithExpr (=expr, =name, .token) {
        super(token)
    }
    
    init: func ~typeAccess (type: Type, .token) {
        super(token)
        name = type getName()
        ref = type getRef()
    }
    
    accept: func (visitor: Visitor) {
        visitor visitVariableAccess(this)
    }
    
    suggest: func (candidate: VariableDecl) -> Bool {
        // trivial impl for now
        ref = candidate
        return true
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        //printf("     - Resolving access to %s (ref = %s)\n", name, ref ? ref toString() : "(nil)")
        
        /*
         * Try to resolve the access
         * 
         * It's far simpler than resolving a function call, we just
         * explore the trail from top to bottom and retain the first match.
         */
        if(!ref) {
            depth := trail size() - 1
            while(depth >= 0) {
                node := trail get(depth)
                node resolveAccess(this)
                if(ref) break // break on first match
                depth -= 1
            }
        }
        
        if(expr) {
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) return response
            //printf("Resolved expr, type = %s\n", expr getType() ? expr getType() toString() : "(nil)")
        }
        
        if(!ref && expr) {
            exprType := expr getType()
            //printf("Null ref and non-null expr (%s), looking in type %s\n", expr toString(), exprType toString())
            typeDecl := exprType getRef()
            if(!typeDecl) {
                //printf("typeDecl not resolved, looping..")
                return Responses LOOP
            }
            typeDecl resolveAccess(this)
        }
        
        return ref ? Responses OK : Responses LOOP
        
    }
    
    getType: func -> Type {
        if(!ref) return null
        if(ref instanceOf(Expression)) {
            return ref as Expression getType()
        }
        return null
    }
    
    toString: func -> String {
        name
    }

}
