import ../frontend/Token
import Conditional, Expression, Visitor

Else: class extends Conditional {

    init: func ~_else (.condition, .token) { super(condition, token) }
    
    accept: func (visitor: Visitor) {
        visitor visitElse(this)
    }
    
}
