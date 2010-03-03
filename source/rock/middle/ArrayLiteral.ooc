import ../frontend/Token
import Literal, Visitor, Type, Expression, FunctionCall, Block,
       VariableDecl, VariableAccess
import tinker/[Response, Resolver, Trail]
import structs/[List, ArrayList]
import text/Buffer

ArrayLiteral: class extends Literal {

    elements := ArrayList<Expression> new()
    type : static Type = null
    
    init: func ~arrayLiteral (.token) {
        super(token)
    }
    
    getElements: func -> List<Expression> { elements }
    
    accept: func (visitor: Visitor) { Exception new(This, "Writing an ArrayLiteral as is!") throw() }

    getType: func -> Type { type }
    
    toString: func -> String {
        if(elements isEmpty()) return "[]"
        
        buffer := Buffer new()
        buffer append('[')
        isFirst := true
        for(element in elements) {
            if(isFirst) isFirst = false
            else        buffer append(", ")
            buffer append(element toString())
        }
        buffer append(']')
        buffer toString()
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        printf(" >> Resolving %s\n", toString())
        
        /*{
            parent := trail peek()
            if(!parent instanceOf()) {
                grandpa := trail peek(2)
                grandpa replace(parent, VariableDecl new())
            }
        }*/
        
        if(type == null) {
            innerType := elements first() getType()
            if(innerType == null || !innerType isResolved()) {
                res wholeAgain(this, "need innerType")
                return Responses OK
            }
                
            type = BaseType new("ArrayList", token)
            type addTypeArg(innerType)
            printf("Decided for type %s\n", type toString())
            
            newCall := FunctionCall new(type, "new", token)
            parent := trail peek()
            grandpa := trail peek(2)
            if(!parent replace(this, newCall)) {
                token throwError("Couldn't replace %s with %s in %s\n" format(toString(), newCall toString(), parent toString()))
            }
            
            block := Block new(token)
            for(element in elements) {
                expr := parent
                if(expr instanceOf(VariableDecl)) {
                    expr = VariableAccess new(expr as VariableDecl, expr token)
                }
                addCall := FunctionCall new(expr, "add", token)
                addCall args add(element)
                block getBody() add(addCall)
            }
            if(!grandpa addAfter(parent, block)) {
                token throwError("Couldn't add %s after %s in %s\n" format(block toString(), parent toString(), grandpa toString()))
            }
            
            res wholeAgain(this, "just replaced")
            return Responses OK
        }
        
        if(type != null) return type resolve(trail, res)
        
        return Responses OK
        
    }

}
