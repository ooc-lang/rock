import ../frontend/Token
import Literal, Visitor, Type, BaseType

IntLiteral: class extends Literal {

    value: Int64
    type : BaseType

    init: func ~intLiteral (=value, .token) {
        super(token)
        type = BaseType new("Int", token)
    }

    accept: func (visitor: Visitor) { visitor visitIntLiteral(this) }

    getType: func -> Type { type }

    toString: func -> String { "%lld" format(value) }

}
