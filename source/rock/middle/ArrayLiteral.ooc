import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, Expression, FunctionCall, Block,
       VariableDecl, VariableAccess, Cast, Node, ClassDecl, TypeDecl
import tinker/[Response, Resolver, Trail]
import structs/[List, ArrayList]
import text/Buffer

ArrayLiteral: class extends Literal {

    unwrapped := false
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
                
                if(type == null)  {
                    type = cast getType()
                    if(type != null) {
                        if(res params veryVerbose) printf(">> Inferred type %s of %s by outer cast %s\n", type toString(), toString(), parent toString())
                        // bitchjump the cast
                        grandpa replace(parent, this)
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
            if(res params veryVerbose) printf("Inferred type %s for %s\n", type toString(), toString())
        }
        
        if(type != null) {
            response := type resolve(trail, res)
            if(!response ok()) return response
            
            if(!unwrapped) {
                parentIdx := 1
                while(trail peek(parentIdx) instanceOf(Cast)) parentIdx+= 1
                
                response = unwrapToArrayList(trail, res, trail peek(parentIdx), trail peek(parentIdx + 1))
                if(!response ok()) return response
            }
        }
        
        return Responses OK
        
    }
    
    // TODO: refactor..
    unwrapToArrayList: func (trail: Trail, res: Resolver, parent, grandpa: Node) -> Response {
        
        realParent := trail peek()
        newCall := FunctionCall new(type, "new", token)
        
        expr : Expression = parent
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
        } else {
            // not in a variable-decl = need to unwrap.
            varDecl := VariableDecl new(type, generateTempName("arrLit"), newCall, token)
            if(!trail addBeforeInScope(realParent, varDecl)) {
                if(res fatal) token throwError("Couldn't add " + varDecl toString() + " before " + parent toString() + " in " + trail toString())
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
        
        // if we're in a varDecl, the initialization is done after. If we're somewhere else, we need to initialize before!
        result := (realParent instanceOf(VariableDecl) ? trail addAfterInScope(realParent, block) : trail addBeforeInScope(realParent, block))
        if(!result) {
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

        unwrapped = true
        res wholeAgain(this, "just replaced")
        return Responses OK
        
    }

}
