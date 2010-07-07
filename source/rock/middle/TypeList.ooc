import structs/[List, ArrayList]
import Type

TypeList: class extends Type {

    types := ArrayList<Type> new()

    init: func ~type (.token) {
        super(token)
    }

    accept: func (visitor: Visitor) { visitor visitType(voidType) }

}

