import io/[Writer], ../io/TabbedWriter
import ../middle/[Visitor, Node]

AwesomeWriter: class extends TabbedWriter {
    
    visitor: Visitor
    
    init: func ~awesome (=visitor,. stream) {
        super(stream)
    }
    
    app: func ~node (node: Node) {
        //printf("Writing a %s, looks like %s\n", node class name, node toString())
        node accept(visitor)
    }
    
    openBlock: func {
        this app("{"). tab()
    }
    
    closeBlock: func {
        this untab(). nl(). app("}")
    }
    
}
