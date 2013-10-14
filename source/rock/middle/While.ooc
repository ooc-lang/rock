import ../frontend/Token
import Conditional, Expression, Visitor

While: class extends Conditional {

    init: func ~_while (.condition, .token) { super(condition, token) }

    clone: func -> This {
        copy := new(condition ? condition clone() : null, token)
        body list each(|e| copy body add(e clone()))
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitWhile(this)
    }

    isDeadEnd: func -> Bool { false }

    toString: func -> String {
        "while (%s)" format(condition toString())
    }

}
