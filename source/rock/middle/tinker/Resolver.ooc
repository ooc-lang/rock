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
        
        if(params veryVerbose) printf("[Module] response = %s (wholeAgain = %s)\n", response toString(), wholeAgain toString())
        
        return !response ok() || wholeAgain
        
    }
    
    wholeAgain: func (node: Node, reason: String) {
        if(params debugLoop) printf("LOOP %s : %s because '%s'\n", node toString(), node class name, reason)
        wholeAgain = true
    }
    
}
