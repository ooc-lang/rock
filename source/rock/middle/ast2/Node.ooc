
import tinker/Resolver

Node: class {

    resolve: func (task: Task) {
        ("Tasking a node, that's in reality a " + class name) println()
        task done()
    }

}
