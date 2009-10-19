import ../frontend/Token
import Statement

Expression: abstract class extends Statement {

    init: func(.token) { super(token) }

}
