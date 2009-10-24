import ../frontend/Token
import Visitor, Expression, VariableDecl, Type

VariableAccess: class extends Expression {

    name: String
    ref: VariableDecl
    
    init: func ~variableAccess (=name, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitVariableAccess(this)
    }
    
    getType: func -> Type {
        ref ? ref type : null
    }

}
