import ../frontend/Token
import Literal, Visitor, Type, BaseType

FloatLiteral: class extends Literal {
    exactValue : String
    value: Float
    type := static BaseType new("Float", nullToken)

    init: func ~floatLiteral (=exactValue, .token) {
      value = exactValue toFloat()
      super(token)
    }

    clone: func -> This { new(exactValue, token) }

    accept: func (visitor: Visitor) { visitor visitFloatLiteral(this) }

    getType: func -> Type { type }

    toString: func -> String { exactValue }

}
