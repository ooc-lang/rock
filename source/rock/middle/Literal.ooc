import ../frontend/Token
import Expression, Node

Literal: abstract class extends Expression {

    init: func (.token) { super(token) }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }

}
