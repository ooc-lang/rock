import ControlStatement, Visitor, Scope

/**
 * A simple block
 */
Block: class extends ControlStatement {

    init: func (.token) { super(token) }

    accept: func (v: Visitor) { v visitBlock(this) }

    isDeadEnd: func -> Bool { true }

    clone: func -> This {
        copy := new(token)
        body list each(|stat| copy body add(stat clone()))
        copy
    }

    toString: func -> String { getBody() toString() }

}
