import structs/[ArrayList]
import VariableAccess, VariableDecl, Statement
import tinker/[Trail, Resolver, Response]

Scope: class extends ArrayList<Statement> {
    
    init: func ~scope {
        T = Statement
        super()
    }
    
    resolveAccess: func (access: VariableAccess) {
        for(stat in this) {
            stat resolveAccess(access)
        }
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {

        for(stat in this) {
            response := stat resolve(trail, res)
            //printf("Response of statement [%s] %s = %s\n", stast class name, stat toString(), response toString())
            if(!response ok()) return response
        }
        
        return Responses OK
        
    }
    
}

