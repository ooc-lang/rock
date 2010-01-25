import ../frontend/Token
import Node, Expression, Visitor, Type
import tinker/[Trail, Resolver, Response]

Parenthesis: class extends Expression {

    inner: Expression

    init: func ~parenthesis (=inner, .token) { super(token) }
    
    accept: func (visitor: Visitor) {
        visitor visitParenthesis(this)
    }
    
    getType: func -> Type {
        inner getType()
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        trail push(this)
        response := inner resolve(trail, res)
        trail pop(this)
        
        printf("Resolved %s in parenthesis, response = %s\n", inner toString(), response toString())
        return response
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case inner => inner = kiddo; true
            case => false
        }
    }
    
    toString: func -> String { "(" + inner toString() + ")" }

}