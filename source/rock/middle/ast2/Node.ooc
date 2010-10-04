
import tinker/Resolver

Node: class {

    resolve: func (task: Task) {
        (task toString() + " node-stub, already done.") println()
        task done()
    }

    toString: func -> String {
        class name
    }

}
