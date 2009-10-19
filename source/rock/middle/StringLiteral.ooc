import ../frontend/Token
import Literal, Visitor

StringLiteral: class extends Literal {

    value: String
    
    init: func ~stringLiteral (=value, .token) { super(token) }
    
    accept: func (visitor: Visitor) { visitor visitStringLiteral(this) }

}
