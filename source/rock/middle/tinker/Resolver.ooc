import ../[Module, Node, Import], structs/List, io/File
import ../../frontend/[BuildParams, Token, AstBuilder]
import Response, Trail, Tinkerer

Resolver: class {

    wholeAgain := false

    lastNode  : Node
    lastReason: String

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
        if(fatal && BuildParams fatalError) {
            lastNode   = node
            lastReason = reason
        }

        if((params veryVerbose || fatal) && params debugLoop) {
            node token printMessage("%s : %s because '%s'\n" format(node toString(), node class name, reason), "LOOP")
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

            // This is beautiful, wonderful code that can't be used in rock
            // right now because it still breaks on 64-bit.

            /*
            tokPointer := nullToken& // yay workarounds (yajit can't push structs)\

            pathElem walk(|f|
                path := f getPath()
                if (!path endsWith(".ooc")) return true

                module := AstBuilder cache get(f getAbsolutePath())

                fullName := f getAbsolutePath()
                fullName = fullName substring(pathElem getAbsolutePath() length() + 1, fullName length() - 4)

                dummyModule addImport(Import new(fullName, tokPointer@))                
                true
            )
            */

            walkForImports(pathElem, pathElem, dummyModule)
        }

        params verbose = false
        params veryVerbose = false
        dummyModule parseImports(this)
        dummyModule getGlobalImports()

    }

    walkForImports: func (f: File, pathElem: File, dummyModule: Module) {

        if(f isDir()) {
            for(child in f getChildren()) {
                walkForImports(child, pathElem, dummyModule)
            }
        } else {
            if (!f getPath() endsWith(".ooc")) return

            fullName := f getAbsolutePath()
            module := AstBuilder cache get(fullName)

            fullName = fullName substring(pathElem getAbsolutePath() length() + 1, fullName length() - 4)
            dummyModule addImport(Import new(fullName, nullToken))       
        }
    }

}

