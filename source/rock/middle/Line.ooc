import Node, Statement, Visitor

/*
Line: class extends Node {

    inner: Statement

    init: func ~line (=inner) {
        super(inner token)
    }

    accept: func (visitor: Visitor) { visitor visitLine(this) }

    replace: func (oldie, kiddo: Node) -> Bool {
        return match oldie {
            case inner => inner = kiddo; true
            case => false
        }
    }

}
*/