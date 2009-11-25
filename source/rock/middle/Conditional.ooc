import ../frontend/Token
import ControlStatement, Expression
import tinker/[Trail, Resolver, Response]

Conditional: abstract class extends ControlStatement {

    condition: Expression

    init: func ~conditional (=condition, .token) { super(token) }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if(condition != null) {
            trail push(this)
            response := condition resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                return response
            }
        }
        
        return super resolve(trail, res)
        
    }

}
