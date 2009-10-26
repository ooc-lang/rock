import ../frontend/Token
import Literal, Visitor, Type

StringLiteral: class extends Literal {

    value: String
    type : static Type = BaseType new("String", nullToken)
    
    init: func ~stringLiteral (=value, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) { visitor visitStringLiteral(this) }

    getType: func -> Type { type }

}
