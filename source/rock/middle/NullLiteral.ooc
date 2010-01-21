import ../frontend/Token
import Expression, Node, Literal, Visitor, Type
import tinker/[Resolver, Response, Trail]

NullLiteral: class extends Literal {

    type : static Type = BaseType new("Pointer", nullToken)

    init: func ~nullLiteral (.token) { super(token) }
    
    getType: func -> Type { type }
    
    accept: func (visitor: Visitor) { visitor visitNullLiteral(this) }

}
