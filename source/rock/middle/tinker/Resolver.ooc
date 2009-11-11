import ../[Module]
import ../../frontend/[BuildParams]
import Response

Resolver: class {
 
    fatal := false
    module: Module
    
    init: func (=module) {}
    
    process: func (params: BuildParams) -> Bool {
 
        response := module resolve()
        
        if(response != Responses OK) {
            true
        }
        
        false
        
    }
    
}
