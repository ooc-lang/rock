
import structs/ArrayList

import tinker/Resolver
import Node, FuncDecl, Call

/**
 * A module contains types, functions, global variables.
 *
 * It has a name, a package, imports (ie. using another module's symbols)
 * uses (for native libraries)
 */
Module: class extends Node {

    /**
     * The fullname is somemthing like: "my/package/MyModule".
     * It doesn't contain ".ooc", and it's always '/', never '\' even
     * on win32 platforms.
     */
    fullName: String

    /**
     * List of functions in thie module that don't belong to any type
     */
    functions := ArrayList<FuncDecl> new()
    
    init: func (=fullName) {}


    resolve: func (task: Task) {
        task queueAll(|queue|
            functions each(|f| queue(f))
        )
        task done()
    }

    resolveCall: func (call: Call, task: Task, suggest: Func (FuncDecl)) {
        functions each(|f|
            if(f name == call name)
                suggest(f)
        )
    }

}

