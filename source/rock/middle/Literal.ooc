import ../frontend/Token
import Expression

Literal: abstract class extends Expression {

    init: func (.token) { super(token) }

}
