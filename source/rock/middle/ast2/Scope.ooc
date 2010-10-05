
import structs/[ArrayList, List]

import tinker/Resolver
import Node, Statement, Var, Access

Scope: class extends Node {

    body: List<Statement> { get set }

    init: func {
        body = ArrayList<Statement> new()
    }

    resolve: func (task: Task) {
        task queueList(body)
        task done()
    }

    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {

        idx := -1

        task walkBackward(|node|
            if(idx == -1 && node instanceOf?(Statement)) {
                idx = body indexOf(node as Statement)
                return true // break
            }
            false
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

    accessResolver?: func -> Bool { true }

    add: func (s: Statement) {
        body add(s)
    }

}

