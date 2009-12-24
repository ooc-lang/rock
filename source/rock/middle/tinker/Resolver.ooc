import ../[Module, Node]
import ../../frontend/[BuildParams]
import Response, Trail

Resolver: class {
 
    fatal := false
    module: Module
    params: BuildParams
    
    init: func (=module, =params) {}
    
    process: func -> Bool {
 
        response := module resolve(Trail new(), this)
        if(params verbose) printf("[Module] response = %s\n", response toString())
        
        if(!response ok()) {
            return true
        }
        
        return false
        
    }
    
}
