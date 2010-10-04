
import structs/ArrayList

import Node, Statement, Call
import tinker/Resolver

FuncDecl: class extends Node {

    resolved := false // artificial testing
    name: String { get set }
    body: ArrayList<Statement> { get set }

    init: func ~fDecl (=name) {
        body = ArrayList<Statement> new()
    }

    resolve: func (task: Task) {
        resolved = true // artificial testing
        task queueAll(|queue|
            body each(|s| queue(s))
        )
        task done()
    }

    toString: func -> String {
        name + ": func"
    }

}
