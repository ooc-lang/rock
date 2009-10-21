import ../frontend/Token
import VariableDecl, Type

Argument: abstract class extends VariableDecl {
    
    init: func ~argument (.type, .token) { super(type, token) }
    
    name: func -> String {
        atoms get(0) as Atom name
    }
    
}

VarArg: class extends Argument {
    
    init: func ~varArg (.type, .token) { super(type, token) }
    
}
