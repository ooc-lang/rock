import ../frontend/Token
import Literal, Visitor, Type, BaseType

CharLiteral: class extends Literal {

    // TODO: maybe the value should be a char? then we'd need escape/unescape code.
    // j/ooc does that. I'm not sure it's too useful
    value: String
    type : BaseType
    
    init: func ~charLiteral (=value, .token) {
        super(token)
        type = BaseType new("Char", token)
    }
    
    accept: func (visitor: Visitor) { visitor visitCharLiteral(this) }
    
    getType: func -> Type { type }

}
