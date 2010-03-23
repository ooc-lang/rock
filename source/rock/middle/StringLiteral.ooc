import ../frontend/Token
import Literal, Visitor, Type
import tinker/[Response, Resolver, Trail]

StringLiteral: class extends Literal {

    value: String
    type : static Type = BaseType new("String", nullToken)
    
    init: func ~stringLiteral (=value, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) { visitor visitStringLiteral(this) }

    getType: func -> Type { This type }
    
    toString: func -> String { "\"" + value + "\"" }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        return This type resolve(trail, res)
    }

}
