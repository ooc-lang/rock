import ../frontend/Token
import Visitor, Expression, VariableDecl, Type
import tinker/[Resolver, Response, Trail]

VariableAccess: class extends Expression {

    expr: Expression
    name: String
    
    ref: VariableDecl
    
    init: func ~variableAccess (.name, .token) {
        this(null, name, token)
    }
    
    init: func ~variableAccessWithExpr (=expr, =name, .token) {
        super(token)
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
        
        printf("     - Resolving access to %s\n", name)
        
        if(expr) {
            trail push(this)
            response := expr resolve(trail, res)
            if(!response ok()) return response
            trail pop(this)
            printf("Resolved expr, type = %s\n", expr getType() ? expr getType() toString() : "(nil)")
        }
        
        /*
         * Try to resolve the access
         * 
         * It's far simpler than resolving a function call, we just
         * go from top to bottom and retain the first match.
         */
        if(!ref) {
            depth := trail size() - 1
            while(depth >= 0) {
                "Trying to get to resolve access from depth %d" format(depth) println()
                node := trail get(depth)
                "Got a %s" format(node class name) println()
                node resolveAccess(this)
                if(ref) break // break on first match
                depth -= 1
            }
        }
        
        return ref ? Responses OK : Responses LOOP
        
    }
    
    getType: func -> Type {
        ref ? ref type : null
    }
    
    toString: func -> String {
        class name + " to " +name
    }

}
