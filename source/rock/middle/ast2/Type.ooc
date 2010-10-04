

import Node
import tinker/Resolver

Type: abstract class extends Node {

    

}


BaseType: class extends Type {

    resolved := false
    name: String { get set }

    init: func (=name) {}

    resolve: func (task: Task) {
        resolved = true
        task done()
    }

}
