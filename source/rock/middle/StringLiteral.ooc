import ../frontend/Token
import Literal, Visitor, Type

StringLiteral: class extends Literal {

    value: String
    type : static Type = BaseType new("String", nullToken)
    
    init: func ~stringLiteral (=value, .token) {
        super(token)
        ("\\o/ \\o/ \\o/ \\o/ Got string literal '" + value + "'") println()
    }
    
    accept: func (visitor: Visitor) { visitor visitStringLiteral(this) }

    getType: func -> Type { type }

}
