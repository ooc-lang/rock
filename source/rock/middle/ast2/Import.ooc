
import Node, Module

/**
 * Imports allow a module to use the functions, types, globals defined
 * in another module.
 *
 * Imports are not transitive, ie. if `A` imports `B` and `B` imports `C`,
 * `A` won't have access to C's symbols if it doesn't import it explicitly.
 */
Import: class extends Node {

    importName: String
    module: Module { get set }

    init: func (=importName) {}

}
