import ../frontend/Token
import Literal, Visitor, Type, BaseType

IntLiteral: class extends Literal {

    value: Int64
    type := static BaseType new("SSizeT", nullToken) // use a signed size_t for performance reasons

    init: func ~intLiteral (=value, .token) {
        super(token)
    }

    clone: func -> This { new(value, token) }

    accept: func (visitor: Visitor) { visitor visitIntLiteral(this) }

    getType: func -> Type { type }

    toString: func -> String { value toString() }

}
