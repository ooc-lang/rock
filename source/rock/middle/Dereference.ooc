import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node
import tinker/[Trail, Resolver, Response]

Dereference: class extends Expression {

    expr: Expression
    
    init: func ~addressOf (=expr, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitDereference(this)
    }
    
    getGenericOperand: func -> Expression {
        if(expr getType() isGeneric() && expr getType() pointerLevel() > 0) {
            return expr
        }
        return super()
    }
    
    getType: func -> Type { expr getType() ? expr getType() dereference() : null }
    
    toString: func -> String {
        return expr toString() + "@"
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        {
            response := expr resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)
        
        return Responses OK
        
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo; true
            case      => false
        }
    }
    
    isReferencable: func -> Bool { true }

}
