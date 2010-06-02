import structs/[ArrayList, List]

import ../../frontend/[BuildParams]
import ../[Module]
import Resolver

Tinkerer: class {

    params: BuildParams
    resolvers := ArrayList<Resolver> new()
    modules: List<Module>
    
    init: func (=params) {}
    
    /**
     * Manipulate the AST.
     * 
     * @return true on success, false on failure
     */
    process: func (=modules) -> Bool {
        
        for(module in modules) {
            resolvers add(Resolver new(module, params, this))
        }
        
        round := 0
        while(!resolvers isEmpty()) {
            
            round += 1
            if(params veryVerbose)
                println("\n=======================================\n\nTinkerer, round " + round + ", " + resolvers size() + " left")
            
            iter := resolvers iterator()
            
            while(iter hasNext()) {
    
                resolver := iter next()
                
                if(params veryVerbose) {
                    printf("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
                    printf("\tResolving module %s", resolver module fullName)
                    printf("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
                }
                
                // returns false = finished resolving
                if(!resolver process()) {
                    if(params veryVerbose) println("++++++++++++++++ Module " + resolver module fullName + " finished resolving.");
                
                    // done? check it and remove it from the processing queue
                    iter remove()
                }
                
            }
            
            if(round == params blowup) {
                for(resolver: Resolver in resolvers) resolver fatal = true
            }
            
            if(round > params blowup) {
                for(res in resolvers) {
                    if(res lastNode != null) {
                        res lastNode token throwError(res lastReason)
                    }
                }
                
                println("Tinkerer going round in circles. " + resolvers size() + " modules remaining.")
                return false
            }
            
        }
        
        true
        
    }
    
}