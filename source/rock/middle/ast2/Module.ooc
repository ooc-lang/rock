
import structs/[ArrayList, List]

import tinker/Resolver
import Node, FuncDecl, Call, Import

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

    /** List of functions in thie module that don't belong to any type */
    functions := ArrayList<FuncDecl> new()

    imports := ArrayList<Import> new()
    
    init: func (=fullName) {}


    resolve: func (task: Task) {
        task queueList(functions)
        task done()
    }

    resolveCall: func (call: Call, task: Task, suggest: Func (FuncDecl)) {
        functions each(|f|
            if(f name == call name)
                suggest(f)
        )
    }

    callResolver?: func -> Bool { true }

    getDeps: func (list := ArrayList<Module> new()) -> List<Module> {
        list add(this)
        imports each(|i|
            if(!list contains?(i module)) {
                i module getDeps(list)
            }
        )
        list
    }

}

