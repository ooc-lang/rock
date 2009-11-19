import ../frontend/Token
import Visitor, Statement, Expression

Return: class extends Statement {

    expr: Expression
    
    init: func ~ret (.token) {
        init(null, token)
    }
    
    init: func ~retWithExpr (=expr, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) { visitor visitReturn(this) }

    toString: func -> String { expr == null ? "return" : "return " + expr toString() }

}


