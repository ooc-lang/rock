import ../[Module, Node, Import], structs/List, io/File
import ../../frontend/[BuildParams, Token, AstBuilder]
import Response, Trail, Tinkerer, Errors

/**
 * Drives the whole 'resolving' part of the compilation process, for
 * an individual module. See Tinkerer for a more general overview.
 *
 * It is passed as the 'res' argument to all AST nodes implementing
 * resolve(). Handles looping (wholeAgain), errors (throwError)
 *
 * Calling wholeAgain(this, "<Explain why you're looping>") from a node's
 * resolve() method
 *
 * @author Amos Wenger (nddrylliog)
 */
Resolver: class {

    /** set to true on wholeAgain() call, reset to false at the beginning of every process() call. */
    wholeAgain := false

    /**
     * Used in Tinkerer to attempt throwing meaningful errors from the
     * last node to have looped, instead of just uninformingly dying
     * on the "Tinkerer going rounds in circle" thing.
     */
    lastNode  : Node
    lastReason: String

    /** True on the last round, where nodes should throw errors if something's wrong. */
    fatal := false

    /** Every module has one resolver. */
    module: Module

    /**
     * Building parameters for this run. We need them for getting
     * the error handler, and knowing if we're in veryVerbose mode
     */
    params: BuildParams

    /**
     *
     */
    tinkerer: Tinkerer

    init: func (=module, =params, =tinkerer) {}

    /**
     * Attempts to resolve the module associated with this resolver.
     *
     * Mostly calls module resolve() with a fresh trail, which is
     * then in charge of resolving its children, which are in turn
     * charged of resolving their own children, and so on.
     *
     * @returns true if the module needs more rounds, false if it's all done.
     */
    process: func -> Bool {
        wholeAgain = false

        response := module resolve(Trail new(), this)
        if(params veryVerbose) "[Module] response = %s (wholeAgain = %s)" printfln(response toString(), wholeAgain toString())

        return !response ok() || wholeAgain
    }

    /**
     * Throw an error. Depending on the error handler and settings,
     * this could either
     *   - Print the error and exit right now, possibly with a [FAIL] print.
     *   - Print the error and continue (default error handler + -allerrors option)
     *   - Do something else, if a custom handler is in place
     */
    throwError: func (e: Error) {
        params errorHandler onError(e)
    }

    /**
     * Marks this module as 'not resolved yet - should continue resolving
     * on next round', but allows to continue resolution of other things
     * in the module for now.
     *
     * A 'reason' for justifying the looping is needed, to allow
     * -debugloop being helpful.
     */
    wholeAgain: func (node: Node, reason: String) {
        if(fatal && params fatalError) {
            lastNode   = node
            lastReason = reason
        }

        if((params veryVerbose && fatal) || params debugLoop) {
            node token formatMessage("%s : %s because '%s'\n" format(node toString(), node class name, reason), "LOOP") println()
        }
        wholeAgain = true
    }

    /**
       Add a module for resolution
     */
    addModule: func (module: Module) {
        tinkerer resolvers add(Resolver new(module, params, tinkerer))
        tinkerer modules add(module)
    }

    /**
       Collect a list of imports to *all* modules present in all the
       sourcepath, and parse these modules so that import getModule()
       correspond to them.

       Used in smart error messages that guess where something is defined.
     */
    collectAllImports: func -> List<Import> {

        dummyModule := Module new("dummy", ".", params, nullToken)

        for (pathElem in params sourcePath getPaths()) {
            pathElem walk(|f|
                // sort out links to non-existent destinations.
                if(!f exists?())
                    return true // = continue

                path := f getPath()
                if (!path endsWith?(".ooc")) return true

                fullName := f getAbsolutePath()
                fullName = fullName substring(pathElem getAbsolutePath() length() + 1, fullName length() - 4)

                dummyModule addImport(Import new(fullName, nullToken))
                true
            )
        }

        params verbose = false
        params veryVerbose = false

        // don't care about errors when looking for hints.
        oldHandler := params errorHandler
        params errorHandler = DevNullErrorHandler new()

        dummyModule parseImports(this)

        // restore the old handler to properly display the 'real' errors.
        params errorHandler = oldHandler

        dummyModule getGlobalImports()

    }

}

