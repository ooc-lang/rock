
import structs/ArrayList

import Node, FuncDecl

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
    
    init: func (=fullName) {
        ("Built module " + fullName) println()
    }

}

