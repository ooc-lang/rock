import ../[Module, Node]
import ../../frontend/[BuildParams]
import Response, Trail

Resolver: class {
 
    wholeAgain := false
 
    fatal := false
    module: Module
    params: BuildParams
    
    init: func (=module, =params) {}
    
    process: func -> Bool {
 
        response : Response = null
        wholeAgain = false

        response = module resolve(Trail new(), this)
        
        if(params verbose) printf("[Module] response = %s\n", response toString())
        
        return !response ok() || wholeAgain
        
    }
    
    wholeAgain: func { wholeAgain = true }
    
}
