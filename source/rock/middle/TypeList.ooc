import structs/[List, ArrayList]
import Type, Visitor, Declaration, VariableAccess
import tinker/[Response, Resolver, Trail]
import ../backend/cnaughty/AwesomeWriter

TypeList: class extends Type {

    types := ArrayList<Type> new()

    init: func ~typeList (.token) {
        super(token)
    }

    accept: func (visitor: Visitor) {
        token throwError("Visiting a TypeList! That shouldn't happen.")
    }

    pointerLevel: func -> Int { 0 }

    checkedDigImpl: func (list: List<Type>, res: Resolver) {
        for(type in types) {
            checkedDigImpl(ArrayList<Type> new(), res)
        }
    }

    write: func (w: AwesomeWriter, name: String) {
        voidType write(w, name)
    }

    equals: func (t: Type) -> Bool {
        if(!t instanceOf(This)) return false
        other := t as This
        if(other types size() != types size()) return false
        for(i in 0..types size()) {
            if(!types[i] equals(other types[i])) return false
        }
        true
    }

    getName: func -> String {
        "<ListType>"
    }

    setRef: func (d: Declaration) {
        token throwError("Trying to set the ref of a TypeList!")
    }

    getRef: func -> Type {
        null
    }

    clone: func -> Type {
        copy := new(token)
        for(type in types) copy types add(type)
        copy
    }

    dereference: func -> Type {
        token throwError("Trying to dereference a TypeList!")
    }

    getTypeArgs: func -> List<VariableAccess> { null }

    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        // there's no use for this method in this class anyway.
        return This NOLUCK_SCORE
    }

    dig: func -> Type {
        copy := new(token)
        for(type in types) copy types add(type dig())
        copy
    }

}

