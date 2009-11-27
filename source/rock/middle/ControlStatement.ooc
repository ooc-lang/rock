import structs/ArrayList
import ../frontend/Token
import Statement, Line, Scope, VariableAccess
import tinker/[Trail, Resolver, Response]

ControlStatement: abstract class extends Statement {

    body := Scope new()
    
    init: func (.token) { super(token) }
    
    resolveAccess: func (access: VariableAccess) {
        body resolveAccess(access)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        //printf("Resolving an %s\n", class name)
        trail push(this)
        response := body resolve(trail, res)
        trail pop(this)
        return response
    }
    
}
