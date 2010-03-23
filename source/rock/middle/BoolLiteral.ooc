import ../frontend/Token
import Literal, Visitor, Type

BoolLiteral: class extends Literal {

    value: Bool
    type : static Type = BaseType new("Bool", nullToken)
    
    init: func ~boolLiteral (=value, .token) { super(token) }
    
    accept: func (visitor: Visitor) { visitor visitBoolLiteral(this) }

    getType: func -> Type { This type }
    getValue: func -> Bool { value }
    
    toString: func -> String {
        value ? "true" : "false"
    }

}
