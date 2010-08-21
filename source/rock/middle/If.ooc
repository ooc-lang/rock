import ../frontend/Token
import Conditional, Expression, Visitor

If: class extends Conditional {

    init: func ~_if (.condition, .token) { super(condition, token) }

    clone: func -> This {
        copy := new(condition ? condition clone() : null, token)
        body list each(|e| copy body add(e clone()))
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitIf(this)
    }

    toString: func -> String {
        "if (" + condition toString() + ")" + body toString()
    }

    isDeadEnd: func -> Bool { false }

}
