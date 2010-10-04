
import structs/ArrayList

import Node, Statement

FuncDecl: class extends Node {

    name: String { get set }
    body: ArrayList<Statement> { get set }

    init: func (=name) {
        ("Built function " + name) println()
        body = ArrayList<Statement> new()
    }

}
