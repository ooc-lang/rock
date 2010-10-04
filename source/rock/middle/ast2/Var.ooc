

import tinker/Resolver
import Type, Expression

Var: class extends Expression {

    _type: Type
    name: String { get set }
    expr: Expression { get set }

    init: func (=name) {}

    getType: func -> Type {
        _type
    }

    resolve: func (task: Task) {
        if(!type) {
            task queue(expr)
            _type = expr getType()
            if(!type)
                Exception new("Couldn't resolve type of " + toString()) throw()
        }

        task queue(type)
        task done()
    }

    toString: func -> String {
        name + (type ? ": " + type toString() : " :") + (expr ? "= " + expr toString() : "")
    }

}

