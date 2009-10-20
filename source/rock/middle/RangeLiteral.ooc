import ../frontend/Token
import Literal, Expression, Visitor

RangeLiteral: class extends Literal {
    
    lower, upper: Expression
    
    init: func ~rangeLiteral (=lower, =upper, .token) { super(token) }
    
    accept: func (visitor: Visitor) {
        visitor visitRangeLiteral(this)
    }
    
}
