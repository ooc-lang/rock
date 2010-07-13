import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, Expression, Node, TypeList, Tuple
import tinker/[Response, Resolver, Trail]
import structs/[List, ArrayList]
import text/Buffer

StructLiteral: class extends Tuple {

    realType : Type = null

    init: func ~structLiteral (=realType, =elements, .token) {
        super(token)
    }

    accept: func (visitor: Visitor) {
        visitor visitStructLiteral(this)
    }

    getType: func -> Type {
        realType
    }

}