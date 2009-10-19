import ../frontend/Token
import Literal, Visitor

IntLiteral: class extends Literal {

    value: Int64
    
    init: func ~intLiteral (=value, .token) { super(token) }
    
    accept: func (visitor: Visitor) { visitor visitIntLiteral(this) }

}
