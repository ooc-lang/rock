import ../frontend/Token
import Node, Expression, Visitor

Parenthesis: class extends Node {

    inner: Expression

    init: func ~parenthesis (=inner, .token) { super(token) }
    
    accept: func (visitor: Visitor) {
        visitor visitParenthesis(this)
    }

}