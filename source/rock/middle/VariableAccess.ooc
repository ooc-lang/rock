import ../frontend/Token
import Visitor, Expression, VariableDecl, Type

VariableAccess: class extends Expression {

    expr: Expression
    name: String
    ref: VariableDecl
    
    init: func ~variableAccess (.name, .token) {
        this(null, name, token)
    }
    
    init: func ~variableAccessWithExpr (=expr, =name, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitVariableAccess(this)
    }
    
    getType: func -> Type {
        ref ? ref type : null
    }
    
    toString: func -> String {
        class name + " to " +name
    }

}
