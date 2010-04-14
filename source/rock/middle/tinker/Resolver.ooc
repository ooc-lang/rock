import ../[Module, Node]
import ../../frontend/[BuildParams, Token]
import Response, Trail, Tinkerer

Resolver: class {
 
    wholeAgain := false
 
    fatal := false
    module: Module
    params: BuildParams
    tinkerer: Tinkerer
    
    init: func (=module, =params, =tinkerer) {}
    
    process: func -> Bool {
 
        response : Response = null
        wholeAgain = false

        response = module resolve(Trail new(), this)
        
        if(params veryVerbose) printf("[Module] response = %s (wholeAgain = %s)\n", response toString(), wholeAgain toString())
        
        return !response ok() || wholeAgain
        
    }
    
    wholeAgain: func (node: Node, reason: String) {
        if(fatal && params fatalError) {
            node token throwError(reason)
        }
        
        if(fatal && params debugLoop) {
            printf("LOOP %s : %s because '%s'\n", node toString(), node class name, reason)
        }
        wholeAgain = true
    }
    
    /**
     * Add a module for resolution
     */
    addModule: func (module: Module) {
        tinkerer resolvers add(Resolver new(module, params, tinkerer))
        tinkerer modules add(module)
    }
    
}
