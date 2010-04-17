import ../frontend/Token
import Expression, Node, Literal, Visitor, Type, BaseType
import tinker/[Resolver, Response, Trail]

NullLiteral: class extends Literal {

    type : BaseType

    init: func ~nullLiteral (.token) {
        super(token)
        type = BaseType new("Pointer", token)
    }
    
    getType: func -> Type { type }
    
    accept: func (visitor: Visitor) { visitor visitNullLiteral(this) }
    
    toString: func -> String { "null" }

}
