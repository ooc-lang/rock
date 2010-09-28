import structs/[List, ArrayList]
import Type, Visitor, Declaration, VariableAccess, FunctionCall
import tinker/[Response, Resolver, Trail]
import ../backend/cnaughty/AwesomeWriter

TypeList: class extends Type {

    types := ArrayList<Type> new()

    init: func ~typeList (.token) {
        super(token)
    }

    accept: func (visitor: Visitor) {
        voidType accept(visitor)
    }

    isResolved: func -> Bool {
        for(type in types) if(!type isResolved()) return false
        true
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        for(type in types) {
            type resolve(trail, res)
        }

        Response OK
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

    equals?: func (t: Type) -> Bool {
        if(!t instanceOf?(This)) return false
        other := t as This
        if(other types getSize() != types getSize()) return false
        for(i in 0..types getSize()) {
            if(!types[i] equals?(other types[i])) return false
        }
        true
    }

    getName: func -> String {
        "<TypeList>"
    }

    toString: func -> String {
        if(types empty?()) return "()"

        buffer := Buffer new()
        buffer append('(')
        isFirst := true
        for(type in types) {
            if(isFirst) isFirst = false
            else        buffer append(", ")
            buffer append(type toString())
        }
        buffer append(')')
        buffer toString()
    }

    setRef: func (d: Declaration) {
        Exception new(This, "Trying to set the ref of a TypeList!") throw()
    }

    getRef: func -> Type {
        this
    }

    clone: func -> Type {
        copy := new(token)
        for(type in types) copy types add(type)
        copy
    }

    realTypize: func (call: FunctionCall) -> Type {
        copy := new(token)
        for(type in types) copy types add(type realTypize(call))
        copy
    }

    dereference: func -> Type {
        Exception new(This, "Trying to dereference a TypeList!") throw()
    }

    getTypeArgs: func -> List<VariableAccess> { null }

    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        match other {
            case list: This =>
                if(list types size != types size) return NOLUCK_SCORE
                
                globalScore := 0.0
                for(i in 0..types size) {
                    score := types[i] getScoreImpl(list types[i], scoreSeed / types size)
                    if(score < 0) {
                        globalScore = score
                        break
                    } else {
                        globalScore += score
                    }
                }
                globalScore as Int
            case =>
                NOLUCK_SCORE
        }
    }

    dig: func -> Type {
        copy := new(token)
        for(type in types) {
            digged := type dig()
            if(digged) copy types add(digged)
            else       return null
        }
        copy
    }

}

