import ../frontend/Token
import Literal, Visitor, Type, BaseType

BoolLiteral: class extends Literal {

    value: Bool
    type : BaseType

    init: func ~boolLiteral (=value, .token) {
        super(token)
        type = BaseType new("Bool", token)
    }

    clone: func -> This { new(value, token) }

    accept: func (visitor: Visitor) { visitor visitBoolLiteral(this) }

    getType: func -> Type { type }
    getValue: func -> Bool { value }

    toString: func -> String {
        value ? "true" : "false"
    }

}
