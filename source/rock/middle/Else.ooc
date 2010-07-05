import ../frontend/Token
import Conditional, Expression, Visitor, Node

Else: class extends Conditional {

    init: func ~_else (.token) { super(null, token) }

    accept: func (visitor: Visitor) {
        visitor visitElse(this)
    }

    toString: func -> String {
        "else"
    }

}
