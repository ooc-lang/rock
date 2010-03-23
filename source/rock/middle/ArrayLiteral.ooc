import ../frontend/Token
import Literal, Visitor, Type, Expression, FunctionCall, Block,
       VariableDecl, VariableAccess, Cast, Node, ClassDecl, TypeDecl
import tinker/[Response, Resolver, Trail]
import structs/[List, ArrayList]
import text/Buffer

ArrayLiteral: class extends Literal {

    elements := ArrayList<Expression> new()
    type : Type = null
    
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
        
        {
            parentIdx := 1
            parent := trail peek(parentIdx)
            if(parent instanceOf(Cast)) {
                cast := parent as Cast
                parentIdx += 1
                grandpa := trail peek(parentIdx)
                
                // bitchjump the cast & move up in the node hierarchy
                grandpa replace(parent, this)
                parent = grandpa
                grandpa = trail peek(parentIdx + 1)
                
                if(type == null)  {
                    type = cast getType()
                    if(type != null) {
                        printf(">> Inferred type %s of %s by outer cast %s\n", type toString(), toString(), parent toString())
                        unwrapToArrayList(trail, res, parent, grandpa)
                    }
                }
            }
            grandpa := trail peek(parentIdx + 1)
            
            if(!parent instanceOf(VariableDecl)) {
                varDecl := VariableDecl new(null, generateTempName("arrLit"), this, token)
                if(!trail addBeforeInScope(parent, varDecl)) {
                    if(res fatal) token throwError("Couldn't add " + varDecl toString() + " before " + parent toString() + " in scope")
                    return Responses LOOP
                }
                parent replace(this, VariableAccess new(varDecl, token))
                res wholeAgain(this, "replaced ourselves with varAcc")
                return Responses OK
            }
        }
        
        trail push(this)
        for(element in elements) {
            response := element resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)
        
        if(type == null) {
            innerType := elements first() getType()
            if(innerType == null || !innerType isResolved()) {
                res wholeAgain(this, "need innerType")
                return Responses OK
            }
                
            type = BaseType new("ArrayList", token)
            type addTypeArg(innerType)
            printf("Inferred type %s for %s\n", type toString(), toString())
            
            unwrapToArrayList(trail, res, trail peek(), trail peek(2))
            return Responses OK
        }
        
        if(type != null) return type resolve(trail, res)
        
        return Responses OK
        
    }
    
    unwrapToArrayList: func (trail: Trail, res: Resolver, parent, grandpa: Node) {
        
        printf("Unwrapping %s to ArrayList, parent = %s, grandpa = %s\n", toString(), parent toString(), grandpa toString())
        
        newCall := FunctionCall new(type, "new", token)
        if(!parent replace(this, newCall)) {
            token throwError("Couldn't replace %s with %s in %s\n" format(toString(), newCall toString(), parent toString()))
        }
        
        block := Block new(token)
        for(element in elements) {
            expr := parent
            if(expr instanceOf(VariableDecl)) {
                vAcc := VariableAccess new(expr as VariableDecl, expr token)
                if(grandpa instanceOf(TypeDecl)) {
                    if(expr as VariableDecl isStatic()) {
                        vAcc expr = VariableAccess new(grandpa as TypeDecl getNonMeta() getInstanceType(), expr token)
                    } else {
                        vAcc expr = VariableAccess new(grandpa as TypeDecl getThisDecl(), expr token)
                    }
                }
                expr = vAcc
            }
            addCall := FunctionCall new(expr, "add", token)
            addCall args add(element)
            block getBody() add(addCall)
        }
        
        if(!trail addAfterInScope(parent, block)) {
            if(grandpa instanceOf(ClassDecl) && parent instanceOf(VariableDecl)) {
                cDecl := grandpa as ClassDecl
                vDecl := parent as VariableDecl
                fDecl := (vDecl isStatic() ? cDecl getLoadFunc() : cDecl getDefaultsFunc())
                fDecl getBody() add(block)
                printf("Just added block with %d statemens to fDecl %s, now fDecl body has %d statements\n", block getBody() size(), fDecl toString(), fDecl getBody() size())
            } else {
                token throwError("Couldn't add %s after %s in %s\n" format(block toString(), parent toString(), grandpa toString()))
            }
        }
        
        res wholeAgain(this, "just replaced")
        
    }

}
