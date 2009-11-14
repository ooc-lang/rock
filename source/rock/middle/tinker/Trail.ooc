import structs/Stack
import ../[Node, Module]

Trail: class extends Stack<Node> {
    
    init: func ~trail {
        T = Node
        super()
    }
    
    pop: func ~verify (reference: Node) -> Node {
        
        popped : Node = pop()
        if(popped != reference) {
            Exception new(This, "Should have popped " + 
                reference toString() + " but popped " + popped toString()) throw()
        }
        return popped
        
    }
    
    module: func -> Module { data get(0) as Module }
    
}
