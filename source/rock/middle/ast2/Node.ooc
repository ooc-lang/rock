
import tinker/Resolver

import Call, FuncDecl // for resolveCall
import Access, Var // for resolveAccess

Node: class {

    resolve: func (task: Task) {
        (task toString() + " node-stub, already done.") println()
        task done()
    }

    toString: func -> String {
        class name
    }

    resolveCall: func (call: Call, task: Task, suggest: Func (FuncDecl)) {
        // bah bah bah.
    }

    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {
        // et des scoubidou bi dou.
    }

}
