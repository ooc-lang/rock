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
        inner resolve(trail, res)
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case inner => inner = oldie; true
            case => false
        }
    }

}