import ../frontend/Token
import ControlStatement, Expression, Visitor, VariableDecl

Foreach: class extends ControlStatement {
    
    variable: VariableDecl
    collection: Expression

    init: func ~_while (=variable, =collection, .token) { super(token) }
    
    accept: func (visitor: Visitor) {
        visitor visitForeach(this)
    }
    
}
