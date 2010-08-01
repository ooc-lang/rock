import ../frontend/Token
import Literal, Visitor, Type, BaseType
import tinker/[Response, Resolver, Trail]

StringLiteral: class extends Literal {

    value: String
    type : BaseType

    init: func ~stringLiteral (=value, .token) {
        super(token)
        type = BaseType new("String", token)
    }

    accept: func (visitor: Visitor) { visitor visitStringLiteral(this) }

    getType: func -> Type { type }

    toString: func -> String { "\"" + value + "\"" }

    size: func -> SizeT { value length() }

}
