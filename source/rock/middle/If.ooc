import ../frontend/Token
import Conditional, Expression, Visitor

If: class extends Conditional {

    init: func ~_if (.condition, .token) { super(condition, token) }
    
    accept: func (visitor: Visitor) {
        visitor visitIf(this)
    }
    
    toString: func -> String {
            "if (" + condition toString() + ")"
    }
    
}
