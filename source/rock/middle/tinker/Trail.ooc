import structs/Stack
import text/StringBuffer
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
    
    find: func (T: Class) -> Int {
        
        i := size() - 1
        while(i >= 0) {
            node : Node = data get(i)
            if(node class inheritsFrom(T)) {
                break
            }
            i -= 1
        }
        
        return i
        
    }
    
    toString: func -> String {
        
        sb := StringBuffer new()
        sb append('\n')
        
        for(i in 0..size()) {
            for(j in 0..i) {
                sb append("  ")
            }
            sb append("\\_, "). append(get(i) toString()). append('\n')
        }
        
        sb toString()
        
    }
    
    get: func (index: Int) -> Node { return data get(index) as Node }
    
    module: func -> Module { data get(0) as Module }
    
}
