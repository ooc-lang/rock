import ../frontend/Token
import VariableDecl, Type, Visitor

Argument: abstract class extends VariableDecl {
    
    init: func ~argument (.type, .name, .token) { super(type, name, token) }
    
}

VarArg: class extends Argument {
    
    init: func ~varArg (.token) { super(null, "<...>", token) }
    
    accept: func (visitor: Visitor) {
        visitor visitVarArg(this)
    }
    
}
