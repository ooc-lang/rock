import ../frontend/Token
import Literal, Visitor, Type

CharLiteral: class extends Literal {

    value: Char
    type : static Type = BaseType new("Char", nullToken)
    
    init: func ~charLiteral (=value, .token) { super(token) }
    
    accept: func (visitor: Visitor) { visitor visitCharLiteral(this) }
    
    getType: func -> Type { type }

}
