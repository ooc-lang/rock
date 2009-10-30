import ../frontend/Token
import VariableDecl, Type

Argument: abstract class extends VariableDecl {
    
    init: func ~argument (.type, .name, .token) { super(type, name, token) }
    
}

VarArg: class extends Argument {
    
    init: func ~varArg (.type, .token) { super(type, "<...>", token) }
    
}
