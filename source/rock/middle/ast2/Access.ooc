

import Expression, Type, Var

Access: class extends Expression {

    name: String { get set }
    expr: Expression { get set }
    
    ref: Var { get set }

    init: func (=expr, =name) {}

    getType: func -> Type {
        ref ? ref type : null
    }

    toString: func -> String {
        name
    }

}
