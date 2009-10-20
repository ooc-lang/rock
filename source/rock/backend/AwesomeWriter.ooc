import io/[Writer], ../io/TabbedWriter
import ../middle/[Visitor, Node]

AwesomeWriter: class extends TabbedWriter {
    
    visitor: Visitor
    
    init: func ~awesome (=visitor,. stream) {
        super(stream)
    }
    
    app: func ~node (node: Node) {
        node accept(visitor)
    }
    
}
