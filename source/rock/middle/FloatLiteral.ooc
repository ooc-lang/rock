import ../frontend/Token
import Literal, Visitor, Type

FloatLiteral: class extends Literal {

    value: Float
    type : static Type = BaseType new("Float", nullToken)
    
    init: func ~floatLiteral (=value, .token) { super(token) }
    
    accept: func (visitor: Visitor) { visitor visitFloatLiteral(this) }

    getType: func -> Type { This type }
    
    toString: func -> String { "%f" format(value) }

}
