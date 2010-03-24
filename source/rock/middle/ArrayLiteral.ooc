import ../frontend/[Token, BuildParams]
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
        
        // bitchjump casts and infer type from them, if they're there (damn you, j/ooc)
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
                        if(res params veryVerbose) printf(">> Inferred type %s of %s by outer cast %s\n", type toString(), toString(), parent toString())
                        response := unwrapToArrayList(trail, res, parent, grandpa)
                        if(!response ok()) return response
                    }
                }
            }
            grandpa := trail peek(parentIdx + 1)
        }
        
        // resolve all elements
        trail push(this)
        for(element in elements) {
            response := element resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)
        
        // if we still don't know our type, resolve from elements' innerTypes
        if(type == null) {
            innerType := elements first() getType()
            if(innerType == null || !innerType isResolved()) {
                res wholeAgain(this, "need innerType")
                return Responses OK
            }
                
            type = BaseType new("ArrayList", token)
            type addTypeArg(innerType)
            printf("Inferred type %s for %s\n", type toString(), toString())
            
            return unwrapToArrayList(trail, res, trail peek(), trail peek(2))
        }
        
        if(type != null) return type resolve(trail, res)
        
        return Responses OK
        
    }
    
    unwrapToArrayList: func (trail: Trail, res: Resolver, parent, grandpa: Node) -> Response {
        
        /*if(res params veryVerbose)*/ printf("Unwrapping %s to ArrayList, parent = %s, grandpa = %s\n", toString(), parent toString(), grandpa toString())
        
        realParent := trail peek()
        printf("realParent = %s\n", realParent toString())
        
        printf("Replacing with new\n")
        newCall := FunctionCall new(type, "new", token)
        
        expr : Expression = this
        if(expr instanceOf(VariableDecl)) {
            if(!parent replace(this, newCall)) {
                token throwError("Couldn't replace %s with %s in %s\n" format(toString(), newCall toString(), parent toString()))
                return Responses LOOP
            }
            
            vAcc := VariableAccess new(expr as VariableDecl, expr token)
            if(grandpa instanceOf(TypeDecl)) {
                if(expr as VariableDecl isStatic()) {
                    vAcc expr = VariableAccess new(grandpa as TypeDecl getNonMeta() getInstanceType(), expr token)
                } else {
                    vAcc expr = VariableAccess new(grandpa as TypeDecl getThisDecl(), expr token)
                }
            }
            expr = vAcc
        } else  {
            printf("parent isn't VariableDecl, unwrapping\n")
            varDecl := VariableDecl new(type, generateTempName("arrLit"), newCall, token)
            if(!trail addBeforeInScope(realParent, varDecl)) {
                if(res fatal) token throwError("Couldn't add " + varDecl toString() + " before " + parent toString() + " in scope")
                return Responses LOOP
            }
            expr = VariableAccess new(varDecl, token)
            parent replace(this, expr)
            res wholeAgain(this, "replaced ourselves with varAcc")
            
            parent = varDecl
            grandpa = trail get(trail findScope())
        }
        
        block := Block new(token)
        for(element in elements) {
            addCall := FunctionCall new(expr, "add", token)
            addCall args add(element)
            block getBody() add(addCall)
        }
        
        printf("expr = %s, parent = %s, trail = %s\n", expr toString(), parent toString(), trail toString())
        if(!trail addBeforeInScope(realParent, block)) {
            if(grandpa instanceOf(ClassDecl) && parent instanceOf(VariableDecl)) {
                cDecl := grandpa as ClassDecl
                vDecl := parent as VariableDecl
                fDecl := (vDecl isStatic() ? cDecl getLoadFunc() : cDecl getDefaultsFunc())
                fDecl getBody() add(block)
                if(res params veryVerbose) printf("Just added block with %d statemens to fDecl %s, now fDecl body has %d statements\n", block getBody() size(), fDecl toString(), fDecl getBody() size())
            } else {
                if(res fatal) token throwError("Couldn't add %s before %s in %s\n" format(block toString(), realParent toString(), trail toString()))
                return Responses LOOP
            }
        }
        
        res wholeAgain(this, "just replaced")
        return Responses OK
        
    }

}
