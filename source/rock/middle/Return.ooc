import ../frontend/Token
import Visitor, Statement, Expression, Node
import tinker/[Response, Resolver, Trail]

Return: class extends Statement {

    expr: Expression
    
    init: func ~ret (.token) {
        init(null, token)
    }
    
    init: func ~retWithExpr (=expr, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) { visitor visitReturn(this) }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if(expr) {
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                return response
            }
        }
        
        return Responses OK
        
    }

    toString: func -> String { expr == null ? "return" : "return " + expr toString() }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo; true
            case => false
        }
    }

}


