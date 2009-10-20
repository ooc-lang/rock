import structs/ArrayList
import ../frontend/Token
import Statement, Line

ControlStatement: abstract class extends Statement {

    body := ArrayList<Line> new()
    
    init: func (.token) { super(token) }
    
}
