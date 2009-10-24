import ../frontend/Token
import Literal, Expression, Visitor, Type

RangeLiteral: class extends Literal {
    
    lower, upper: Expression
    type : static Type = BaseType new("Range", nullToken)
    
    init: func ~rangeLiteral (=lower, =upper, .token) { super(token) }
    
    accept: func (visitor: Visitor) {
        visitor visitRangeLiteral(this)
    }
    
    getType: func -> Type { type }
    
}
