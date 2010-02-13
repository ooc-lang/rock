import ../frontend/Token
import Visitor, Statement, Expression, Node, FunctionDecl, FunctionCall,
       VariableAccess, AddressOf, ArrayAccess
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
        
        //println("/- Resolving " + toString() + ", trail = " + trail toString())
        idx := trail find(FunctionDecl)
        if(idx != -1) {
            fDecl := trail get(idx) as FunctionDecl
            retType := fDecl getReturnType()
            if(!retType isResolved()) {
                return Responses LOOP
            }
            
            if(fDecl getReturnType() isGeneric()) {
                //println(fDecl toString() + " has a generic return type, replacing self with memcpy!")
                //println("trail peek() is " + trail peek() toString())
                
                if(expr getType() == null || !expr getType() isResolved()) {
                    res wholeAgain(this, "expr type is unresolved"); return Responses OK
                }
                
                fCall := FunctionCall new("memcpy", token)
                fCall args add(VariableAccess new(fDecl getReturnArg(), token))
                fCall args add((expr getType() isGeneric() && !(expr instanceOf(ArrayAccess))) ? expr : AddressOf new(expr, expr token))
                fCall args add(VariableAccess new(VariableAccess new(fDecl getReturnType() getName(), token), "size", token))
                result := trail peek() replace(this, fCall)
                //println("was the replace a success? " + result toString())
                
                if(!result) {
                    token throwError("Couldn't replace ourselves (a return) with a memcpy/assignment! trail = " + trail toString())
                }
                
                return Responses LOOP
            }
        }
        
        return Responses OK
        
    }

    toString: func -> String { expr == null ? "return" : "return " + expr toString() }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        if(expr == oldie) {
            println("replacing expr " + expr toString() + " with  kiddo " + kiddo toString())
            expr = kiddo
            return true
        }
        
        return false
    }

}


