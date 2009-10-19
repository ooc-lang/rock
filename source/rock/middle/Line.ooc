import Node, Statement, Visitor

Line: class extends Node {

    inner: Statement
    
    init: func ~line (=inner) {
        super(inner token)
    }
    
    accept: func (visitor: Visitor) { visitor visitLine(this) }
    
}
