import ../[Module, Node]
import ../../frontend/[BuildParams]
import Response, Trail

Resolver: class {
 
    fatal := false
    module: Module
    
    init: func (=module) {}
    
    process: func (params: BuildParams) -> Bool {
 
        response := module resolve(Trail new(), this)
        printf("response = %s\n", response toString())
        
        if(!response ok()) {
            return true
        }
        
        return false
        
    }
    
}
