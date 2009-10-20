import ../frontend/Token
import ControlStatement, Expression

Conditional: abstract class extends ControlStatement {

    condition: Expression

    init: func ~conditional (=condition, .token) { super(token) }

}
