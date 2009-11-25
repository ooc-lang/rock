import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type
import tinker/[Resolver, Trail, Response]

include stdint

CompType: cover from Int32 {

    toString: func -> String {
        CompTypes repr get(this)
    }
    
}

CompTypes: class {
    equal = 1,
    notEqual = 2,
    greaterThan = 3,
    smallerThan = 4,
    greaterOrEqual = 5,
    smallerOrEqual = 6 : static const CompType
    
    repr := static ["no-op",
        "==",
        "!=",
        ">",
        "<",
        ">=",
        "<="] as ArrayList<String>
}

Comparison: class extends Expression {

    left, right: Expression
    compType: CompType
    type := static BaseType new("Bool", nullToken)
    
    init: func ~comparison (=left, =right, =compType, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitComparison(this)
    }
    
    getType: func -> Type { type }
    
    toString: func -> String {
        return left toString() + CompTypes repr get(compType) + right toString()
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        {
            response := left resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        {
            response := right resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)
        
        return Responses OK
        
    }

}
