import ../frontend/Token
import Statement, Type

Expression: abstract class extends Statement {

    init: func(.token) { super(token) }
    
    getType: abstract func -> Type
    
    isReferencable: func -> Bool { false }

}
