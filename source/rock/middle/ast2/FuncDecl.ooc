
import structs/ArrayList

import Node, Statement
import tinker/Resolver

FuncDecl: class extends Node {

    name: String { get set }
    body: ArrayList<Statement> { get set }

    init: func ~fDecl (=name) {
        body = ArrayList<Statement> new()
    }

    resolve: func (task: Task) {
        task queueAll(|queue|
            body each(|s| queue(s))
        )
        task done()
    }

}
