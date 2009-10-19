import structs/ArrayList
import ../frontend/Token
import Visitor, Expression

FunctionCall: class extends Expression {

    name: String
    args := ArrayList<Expression> new()
    
    init: func ~funcCall (=name, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitFunctionCall(this)
    }

}
