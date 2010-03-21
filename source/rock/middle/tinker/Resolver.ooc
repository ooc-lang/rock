import ../[Module, Node]
import ../../frontend/[BuildParams]
import Response, Trail

Resolver: class {
 
    wholeAgain := false
 
    fatal := false
    module: Module
    params: BuildParams
    magicCount := 10
    
    init: func (=module, =params) {}
    
    process: func -> Bool {
 
        response : Response = null
        wholeAgain = false

        magicCount -= 1
        if(magicCount > 0) {
            printf("KALAMAZOO magic tour %d\n", magicCount)
            trail := Trail new()
            trail push(module)
            for(tDecl in module types) {
                tDecl ghostTypeParams(trail, this)
            }
            return true
        }
        
        response = module resolve(Trail new(), this)
        
        if(params veryVerbose) printf("[Module] response = %s (wholeAgain = %s)\n", response toString(), wholeAgain toString())
        
        return !response ok() || wholeAgain
        
    }
    
    wholeAgain: func (node: Node, reason: String) {
        if(params veryVerbose) printf("%s (of type %s) wants to wholeAgain() because '%s'\n", node toString(), node class name, reason)
        wholeAgain = true
    }
    
}
