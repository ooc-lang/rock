import ../frontend/Token
import Literal, Visitor

CharLiteral: class extends Literal {

    value: Char
    
    init: func ~charLiteral (=value, .token) { super(token) }
    
    accept: func (visitor: Visitor) { visitor visitCharLiteral(this) }

}
