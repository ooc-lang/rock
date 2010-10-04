
import tinker/Resolver

import Call, FuncDecl // for resolveCall

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

}
