import ControlStatement, Visitor, Scope

/**
 * A simple block
 */
Block: class extends ControlStatement {

    init: func (.token) { super(token) }

    accept: func (v: Visitor) { v visitBlock(this) }

    clone: func -> This {
        copy := new(token)
        body list each(|e| copy body add(e clone()))
        copy
    }

    toString: func -> String { getBody() toString() }

}
