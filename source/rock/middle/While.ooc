import ../frontend/Token
import Conditional, Expression, Visitor

While: class extends Conditional {

    init: func ~_while (.condition, .token) { super(condition, token) }
    
    accept: func (visitor: Visitor) {
        visitor visitWhile(this)
    }
    
}
