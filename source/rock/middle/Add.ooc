import ../frontend/Token
import Expression, Visitor

Add: class extends Expression {

    left, right: Expression
    
    init: func ~add (=left, =right, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitAdd(this)
    }

}
