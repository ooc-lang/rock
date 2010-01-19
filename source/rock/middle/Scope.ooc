import structs/[ArrayList]
import VariableAccess, VariableDecl, Statement, Node
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
            //printf("Response of statement [%s] %s = %s\n", stat class name, stat toString(), response toString())
            if(!response ok()) return response
        }
        
        return Responses OK
        
    }
    
    addBefore: func (mark, newcomer: Node) -> Bool {
        
        //printf("Should add %s before %s\n", newcomer toString(), mark toString())
        
        idx := indexOf(mark)
        //printf("idx = %d\n", idx)
        if(idx != -1) {
            add(idx, newcomer)
            //println("|| adding newcomer " + newcomer toString() + " at idx " + idx toString())
            return true
        } else {
            //printf("content of body = \n")
            for(e in this) {
                printf("    ")
                e toString() println()
            }
            
            return false
        }
        
        return false
        
    }
    
    addAfter: func (mark, newcomer: Node) -> Bool {
        
        //printf("Should add %s after %s\n", newcomer toString(), mark toString())
        
        idx := indexOf(mark)
        //printf("idx = %d\n", idx)
        if(idx != -1) {
            add(idx + 1, newcomer)
            //println("|| adding newcomer " + newcomer toString() + " at idx " + (idx + 1) toString())
            return true
        } else {
            //printf("content of body = \n")
            for(e in this) {
                printf("    ")
                e toString() println()
            }
            
            return false
        }
        
        return false
        
    }
    
    
}

