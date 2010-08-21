import ../frontend/Token
import Literal, Visitor, Type, BaseType
import tinker/[Response, Resolver, Trail]

StringLiteral: class extends Literal {

    value: String
    type := static BaseType new("String", nullToken)

    init: func ~stringLiteral (=value, .token) {
        super(token)
    }

    clone: func -> This { new(value clone(), token) }

    accept: func (visitor: Visitor) { visitor visitStringLiteral(this) }

    getType: func -> Type { type }

    toString: func -> String { "\"" + value + "\"" }

    size: func -> SizeT { value length() }

}
