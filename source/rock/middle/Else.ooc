import ../frontend/Token
import Conditional, Expression, Visitor, Node

Else: class extends Conditional {

    init: func ~_else (.token) { super(null, token) }

    clone: func -> This {
        copy := new(token)
        body list each(|e| copy body add(e clone()))
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitElse(this)
    }

    toString: func -> String {
        "else"
    }

}
