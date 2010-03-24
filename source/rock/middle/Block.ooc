import ControlStatement, Visitor

/**
 * A simple block
 */
Block: class extends ControlStatement {
    
    init: func (.token) { super(token) }

    accept: func (v: Visitor) { v visitBlock(this) }
    
    toString: func -> String { getBody() toString() }
    
}
