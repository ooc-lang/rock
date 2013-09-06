import io/[Writer], ../../io/TabbedWriter
import ../../middle/[Visitor, Node]

/**
 * Extension of TabbedWriter that allows to handle
 * blocks opening/closing and appending of nodes.
 */
AwesomeWriter: class extends TabbedWriter {

    visitor: Visitor

    init: func ~awesome (=visitor, .stream) {
        super(stream)
    }

    app: func ~node (node: Node) {
        node accept(visitor)
    }

    openBlock: func {
        this app("{"). tab()
    }

    closeBlock: func {
        this untab(). nl(). app("}")
    }

}
