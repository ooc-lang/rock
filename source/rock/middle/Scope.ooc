import structs/[ArrayList]
import Line, VariableAccess, VariableDecl
import tinker/[Trail, Resolver, Response]

Scope: class extends ArrayList<Line> {
    
    init: func ~scope {
        T = Line
        super()
    }
    
    resolveAccess: func (access: VariableAccess) {
        for(line in this) {
            line inner resolveAccess(access)
        }
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {

        for(line in this) {
            response := line inner resolve(trail, res)
            //printf("Response of line inner [%s] %s = %s\n", line inner class name, line inner toString(), response toString())
            if(!response ok()) return response
        }
        
        return Responses OK
        
    }
    
}

