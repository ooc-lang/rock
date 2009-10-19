import structs/ArrayList
import ../frontend/Token
import Expression, Line, Type, Visitor

FunctionDecl: class extends Expression {

    name : String
    returnType := voidType
    
    body := ArrayList<Line> new()

    init: func ~funcDecl (=name, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) { visitor visitFunctionDecl(this) }
    
}
