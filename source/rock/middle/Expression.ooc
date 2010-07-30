import ../frontend/Token
import Statement, Type, AddressOf

Expression: abstract class extends Statement {

    init: func(.token) { super(token) }

    getType: abstract func -> Type

    isReferencable: func -> Bool { false }

    getGenericOperand: func -> Expression {
        getType() isGeneric() ? this : AddressOf new(this, token)
    }

    clone: abstract func -> This

}
