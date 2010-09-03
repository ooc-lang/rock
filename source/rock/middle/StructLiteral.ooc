import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, Expression, Node, TypeList, Tuple
import tinker/[Response, Resolver, Trail]
import structs/[List, ArrayList]

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

/*
AnonymousStructType: class extends Type {

    types := ArrayList<Type> new()

    init: super func ~type

    pointerLevel: func -> Int { 0 }

    equals?: func (t: Type) -> Bool {
        if(t class != class) return false
        other := t as This
        if(other types size != types size) return false
        for(i in 0..types size) {
            if(!other types[i] equals?(types[i])) return false
        }
        true
    }

    write: func (w: AwesomeWriter, name: String) {
        
    }

}
*/

