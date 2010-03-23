import ../frontend/Token
import Literal, Expression, Visitor, Type, Node
import tinker/[Resolver, Response, Trail]

RangeLiteral: class extends Literal {
    
    lower, upper: Expression
    type : static Type = BaseType new("Range", nullToken)
    
    init: func ~rangeLiteral (=lower, =upper, .token) { super(token) }
    
    accept: func (visitor: Visitor) {
        visitor visitRangeLiteral(this)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        {
            response := super(trail, res)
            if(!response ok()) return response
        }
        
        trail push(this)
        
        {
            response := lower resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        {
            response := upper resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        trail pop(this)
        
        return Responses OK
    }
    
    getType: func -> Type { This type }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case lower => lower = kiddo; true
            case upper => upper = kiddo; true
            case => false
        }
    }
    
}
