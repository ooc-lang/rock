import structs/[ArrayList, List], os/Env

import ../../frontend/[BuildParams]
import ../[Module]
import Resolver

/**
 * Resolve all modules with the help of Resolver, by looping as many
 * times as needed.
 *
 * On the 'params blowup'-nth loop, 'resolver fatal' becomes true
 * and modules know they can begin to throw errors. Don't throw
 * errors on previous rounds unless you're *really really sure*
 * that there's no way it'll be resolved in subsequent runs.
 *
 * If we loop more than params blowup and no one has thrown any
 * error, then we fail with the infamous "Tinkerer is going round
 * in circles". That should really never happen for users. They might
 * just go ahead and start reading code - which would be bad publicity.
 *
 * @author Amos Wenger (nddrylliog)
 */
Tinkerer: class {

    params: BuildParams

    /** Exactly one per module. Removed as soon as the module is resolved */
    resolvers := ArrayList<Resolver> new()

    /**
     * All the modules we have to resolve. Usually, all modules recursively
     * imported from the 'main' module.
     */
    modules: List<Module>

    init: func (=params) {}

    /**
     * Resolve all modules until they're all set, or we failed because
     * we reached blowup.
     *
     * @return true on success, false on failure
     */
    process: func (=modules) -> Bool {

        for(module in modules) {
            resolvers add(Resolver new(module, params, this))
        }

        // this was experimental stuff to figure out if the order modules
        // were resolved in was actually meaningful and impacted on speed
        // and total number of rounds. It turns out - not so much. But I'm
        // leaving that here, because it's interesting. -- nddrylliog
        if (Env get("ROCK_SORT") == "1") {
            printf("Sorting!\n")
            resolvers sort(|r1, r2|
                r1 module timesImported < r2 module timesImported
            )
        }

        if(params stats) {
            for(res in resolvers) {
                module := res module
                printf(" - imported %dx, has %d deps, %s\n", module timesImported, module getAllImports() size(), module fullName)
            }
            printf("End final order.\n")
        }

        round := 0
        while(!resolvers empty?()) {

            round += 1
            if(params veryVerbose) {
                println("\n=======================================\n\nTinkerer, round " + round + ", " + resolvers size() + " left")
            }

            iter := resolvers iterator()

            while(iter hasNext?()) {

                resolver := iter next()

                if(params veryVerbose) {
                    printf("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
                    printf("\tResolving module %s", resolver module fullName)
                    printf("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
                }

                resolver module timesLooped += 1

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

                if(params fatalError) {
                    println("Tinkerer going round in circles. " + resolvers size() + " modules remaining.")
                }
                return false
            }

        }

         if(params stats) {
            totalImports := 0
            totalLoops := 0
            for(module in modules) {
                printf(" - imported %dx, has %d deps, looped %d x, %s\n", module timesImported, module getAllImports() size(),
                    module timesLooped, module fullName)
                totalImports += module getAllImports() size()
                totalLoops += module timesLooped
            }
            printf("Total imports = %d, total modules looped = %d, final round = %d\n", totalImports, totalLoops, round)
        }

        true

    }

}