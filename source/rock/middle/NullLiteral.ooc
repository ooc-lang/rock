import ../frontend/Token
import Expression, Node, Literal, Visitor, Type, BaseType
import tinker/[Resolver, Response, Trail]

NullLiteral: class extends Literal {

    type := static BaseType new("Pointer", nullToken)

    init: func ~nullLiteral (.token) {
        super(token)
    }

    clone: func -> This {
        new(token)
    }

    getType: func -> Type { type }

    accept: func (visitor: Visitor) { visitor visitNullLiteral(this) }

    toString: func -> String { "null" }

}
