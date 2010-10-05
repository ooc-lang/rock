
import Expression, Type
import tinker/Resolver

StringLit: class extends Expression {

    value: String
    type := static BaseType new("String")

    init: func (=value) {}

    resolve: func (task: Task) {
        task queue(type)
        task done()
    }

    getType: func -> Type { type }

    toString: func -> String {
        "\"" + value + "\""
    }

}
