
import structs/ArrayList

import tinker/Resolver
import Node, Statement, Var, Access

Scope: class extends Node {

    body: ArrayList<Statement> { get set }

    init: func {
        body = ArrayList<Statement> new()
    }

    resolve: func (task: Task) {
        task queueAll(|queue|
            body each(|s| queue(s))
        )
        task done()
    }

    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {

        idx := -1

        task walkBackward(|node|
            // TODO: find a way to break out of it
            if(idx == -1 && node instanceOf?(Statement)) {
                idx = body indexOf(node as Statement)
            }
        )
        if(idx == -1) return

        for(i in 0..idx) {
            match (node := body[i]) {
                case v: Var =>
                    if(v name == acc name)
                        suggest(v)
            }
        }
    }

    add: func (s: Statement) {
        body add(s)
    }

}

