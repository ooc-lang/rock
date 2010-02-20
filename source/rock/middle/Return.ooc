import ../frontend/Token
import Visitor, Statement, Expression, Node, FunctionDecl, FunctionCall,
       VariableAccess, AddressOf, ArrayAccess, If, BinaryOp
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
        
        if(!expr) return Responses OK
        
        {
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                return response
            }
        }
        
        idx := trail find(FunctionDecl)
        if(idx != -1) {
            fDecl := trail get(idx) as FunctionDecl
            retType := fDecl getReturnType()
            if(!retType isResolved()) {
                return Responses LOOP
            }
            
            if(fDecl getReturnType() isGeneric()) {
                if(expr getType() == null || !expr getType() isResolved()) {
                    res wholeAgain(this, "expr type is unresolved"); return Responses OK
                }
                
                returnAcc := VariableAccess new(fDecl getReturnArg(), token)
                
                if1 := If new(returnAcc, token)
                
                ass := BinaryOp new(returnAcc, expr, OpTypes ass, token)
                if1 getBody() add(ass)
                
                if(!trail peek() addBefore(this, if1)) {
                    token throwError("Couldn't add the memcpy before the generic return in a %s! trail = %s" format(trail peek() as Node class name, trail toString()))
                }
                expr = null
            }
        }
        
        return Responses OK
        
    }

    toString: func -> String { expr == null ? "return" : "return " + expr toString() }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        if(expr == oldie) {
            expr = kiddo
            return true
        }
        
        return false
    }

}


