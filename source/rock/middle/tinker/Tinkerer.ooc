import structs/[ArrayList, List], os/Env

import ../../frontend/[BuildParams]
import ../[Module]
import Resolver, Errors

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

        round := 0
        while(!resolvers empty?()) {

            round += 1
            if(params veryVerbose) {
                "\n=======================================\n\nTinkerer, round %d, %d left" format(round , resolvers getSize()) println()
            }

            iter := resolvers iterator()

            while(iter hasNext?()) {

                resolver := iter next()

                if(params veryVerbose) {
                    "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" println()
                    ("\tResolving module " + resolver module fullName) println()
                    ("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++") println()
                }

                resolver module timesLooped += 1

                // returns false = finished resolving
                if(!resolver process()) {
                    if(params veryVerbose) ("++++++++++++++++ Module " + resolver module fullName + " finished resolving.") println()

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
                        res throwError(InternalError new(res lastNode token, res lastReason))
                    }
                }

                if(params fatalError) {
                    println("Tinkerer going round in circles. " + resolvers getSize() toString() + " modules remaining.")
                }
                return false
            }

        }

        true

    }

}
