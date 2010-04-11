import ../frontend/Token
import Literal, Visitor, Type, BaseType

IntLiteral: class extends Literal {

    value: Int64
    type := static BaseType new("Int", nullToken)
    
    init: func ~intLiteral (=value, .token) { super(token) }
    
    accept: func (visitor: Visitor) { visitor visitIntLiteral(this) }

    getType: func -> Type { This type }
    
    toString: func -> String { "%lld" format(value) }

}
