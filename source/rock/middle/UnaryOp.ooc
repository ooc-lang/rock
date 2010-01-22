import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall
import tinker/[Trail, Resolver, Response]

include stdint

UnaryOpType: cover from Int8 {

    toString: func -> String {
        UnaryOpTypes repr get(this)
    }
    
}

UnaryOpTypes: class {
    binaryNot  = 1,        /*  ~  */
    logicalNot = 2,        /*  !  */
    unaryMinus = 3         /*  -  */ : static const UnaryOpType
    
    repr := static ["no-op",
        "~",
        "!",
        "-"] as ArrayList<String>
}

UnaryOp: class extends Expression {

    inner: Expression
    type: UnaryOpType
    
    init: func ~unaryOp (=inner, =type, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitUnaryOp(this)
    }
    
    getType: func -> Type { inner getType() }
    
    toString: func -> String {
        return UnaryOpTypes repr get(type) + inner toString()
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        
        {
            response := inner resolve(trail, res)
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
            case inner => inner = kiddo; true
            case => false
        }
    }
    
}