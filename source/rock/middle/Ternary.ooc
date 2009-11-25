import ../frontend/Token
import Expression, Visitor, Type
import tinker/[Response, Resolver, Trail]

Ternary: class extends Expression {
    
    condition, ifTrue, ifFalse : Expression

    init: func ~ternary (=condition, =ifTrue, =ifFalse, .token) {
        printf("Got a ternary with condition = %s\n", condition toString())
        printf("  ...ifTrue = %s\n", ifTrue toString())
        printf("and ifFalse = %s\n", ifFalse toString())
        super(token)
    }

    getType: func -> Type {
        // hmm it would probably be good to check that ifTrue and ifFalse have compatible types
        ifTrue getType()
    }
    
    accept: func (visitor: Visitor) {
        visitor visitTernary(this)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        {
            response := condition resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        {
            response := ifTrue resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        {
            response := ifFalse resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)
        
        return Responses OK
        
    }
    
    toString: func -> String { condition toString() + " ? " + ifTrue toString() + " : " + ifFalse toString() }
    
}
