import ../frontend/Token
import Literal, Expression, Visitor, Type, Node

RangeLiteral: class extends Literal {
    
    lower, upper: Expression
    type : static Type = BaseType new("Range", nullToken)
    
    init: func ~rangeLiteral (=lower, =upper, .token) { super(token) }
    
    accept: func (visitor: Visitor) {
        visitor visitRangeLiteral(this)
    }
    
    getType: func -> Type { type }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case lower => lower = kiddo; true
            case upper => upper = kiddo; true
            case => false
        }
    }
    
}
