import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, VariableDecl,
       VariableAccess, BinaryOp, ArrayCreation
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
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        
        {
            response := inner resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        {
            response := type resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        trail pop(this)
        
        // Casting to an arrayType isn't innocent
        if(type instanceOf(ArrayType)) {
            arrType := type as ArrayType
            parent := trail peek()
            
            if(parent instanceOf(VariableDecl)) {
                varDecl := parent as VariableDecl
                varDecl setType(null)
                varDecl setExpr(ArrayCreation new(type as ArrayType, token))
                
                arrTypeAcc := VariableAccess new(arrType inner, token)
                copySize := BinaryOp new(arrType expr, VariableAccess new(arrTypeAcc, "size", token), OpTypes mul, token)
                
                memcpyCall := FunctionCall new("memcpy", token)
                memcpyCall args add(VariableAccess new(VariableAccess new(varDecl, token), "data", token))
                memcpyCall args add(inner)
                memcpyCall args add(copySize)
                
                trail addAfterInScope(varDecl, memcpyCall)
            } else {
                if(res fatal) {
                    Exception new(This, "Casting to ArrayType %s in unrecognized parent node %s (%s)!" format(type toString(), parent toString(), parent class name)) throw()
                } else {
                    res wholeAgain(this, "Mysterious parent.")
                }
            }
        }
        
        return Responses OK
        
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case inner => inner = kiddo; true
            case type  => type = kiddo; true
            case => false
        }
    }

}
