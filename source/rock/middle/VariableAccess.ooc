import ../frontend/Token
import Visitor, Expression

VariableAccess: class extends Expression {

    name: String
    
    init: func ~variableAccess (=name, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitVariableAccess(this)
    }

}
