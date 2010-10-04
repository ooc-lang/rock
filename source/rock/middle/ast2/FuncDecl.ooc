
import structs/ArrayList

import Node, Statement, Call, Scope
import tinker/Resolver

FuncDecl: class extends Node {

    resolved := false // artificial testing
    name: String { get set }
    body := Scope new()

    init: func ~fDecl (=name) {}

    resolve: func (task: Task) {
        resolved = true // artificial testing
        task queue(body)
        task done()
    }

    toString: func -> String {
        name + ": func"
    }

}
