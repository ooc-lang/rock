import ../frontend/Token
import ControlStatement, Expression, Visitor, VariableDecl, Node

Foreach: class extends ControlStatement {
    
    variable: Expression
    collection: Expression

    init: func ~_while (=variable, =collection, .token) { super(token) }
    
    accept: func (visitor: Visitor) {
        visitor visitForeach(this)
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case variable => variable = kiddo; true
            case collection => collection = kiddo; true
            case => false
        }
    }
    
}
