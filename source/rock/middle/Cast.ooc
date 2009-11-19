import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type
import tinker/[Response, Resolver, Trail]

Cast: class extends Expression {

    inner: Expression
    type: Type
    
    init: func ~cast (=inner, =type, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitCast(this)
    }
    
    getType: func -> Type { type }
    
    toString: func -> String {
        return inner toString() + " as " + type toString()
    }
    
    resolve: func (trail: Trail, res: Response) -> Response {
        
        {
            response := inner resolve(trail, res)
            if(!response ok()) return response
        }
        {
            response := type resolve(trail, res)
            if(!response ok()) return response
        }
        
        return Responses OK
        
    }

}
