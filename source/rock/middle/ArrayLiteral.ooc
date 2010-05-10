import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, Expression, FunctionCall, Block,
       VariableDecl, VariableAccess, Cast, Node, ClassDecl, TypeDecl, BaseType,
       Statement, IntLiteral, BinaryOp, Block, ArrayCreation, FunctionCall,
       FunctionDecl
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
    
    accept: func (visitor: Visitor) { 
        visitor visitArrayLiteral(this)
    }

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
        
        readyToUnwrap := true
        
        // bitchjump casts and infer type from them, if they're there (damn you, j/ooc)
        {
            parentIdx := 1
            parent := trail peek(parentIdx)
            if(parent instanceOf(Cast)) {
                cast := parent as Cast
                parentIdx += 1
                grandpa := trail peek(parentIdx)
                
                if(type == null || !type equals(cast getType()))  {
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
        
        // infer type from parent function call, if any, and add an implicit cast
        {
            parent := trail peek()
            if(parent instanceOf(FunctionCall)) {
                fCall := parent as FunctionCall
                index := fCall args indexOf(this)
                if(index != -1) {
                    if(fCall getRef() == null) {
                        res wholeAgain(this, "Need call ref to infer type")
                        readyToUnwrap = false
                    } else {
                        targetType := fCall getRef() args get(index) getType()
                        if(type == null || !type equals(targetType)) {
                            cast := Cast new(this, targetType, token)
                            if(!parent replace(this, cast)) {
                                token throwError("Couldn't replace %s with %s in %s" format(toString(), cast toString(), parent toString()))
                            }
                            res wholeAgain(this, "Replaced with a cast")
                            return Responses OK
                        }
                    }
                }
            }
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
                
            type = ArrayType new(innerType, IntLiteral new(elements size(), token), token)
            if(res params veryVerbose) printf("Inferred type %s for %s\n", type toString(), toString())
        }
        
        if(type != null) {
            response := type resolve(trail, res)
            if(!response ok()) return response
        }
        
        if(readyToUnwrap && type instanceOf(ArrayType)) {
            arrType := type as ArrayType
            
            parentIdx := 1
            parent := trail peek(parentIdx)
            while(parent instanceOf(Cast)) {
                parentIdx += 1
                parent = trail peek(parentIdx)
            }
            
            vDecl : VariableDecl = null
            
            if(parent instanceOf(VariableDecl)) {
                vDecl = parent as VariableDecl
            } else {
                vDecl = VariableDecl new(null, generateTempName("arrLit"), token)
                if(!parent replace(this, VariableAccess new(vDecl, token))) {
                    if(res fatal) {
                        token throwError("Couldn't replace %s with varAcc in %s" format(toString(), parent toString()))
                    }
                    res wholeAgain(this, "Trail is messed up, gotta loop.")
                    return Responses OK
                }
                if(!trail addBeforeInScope(this, vDecl)) {
                    token throwError("Couldn't add %s before in scope." format(vDecl toString()))
                }
            }
    
            vDecl setType(null)
            vDecl setExpr(ArrayCreation new(type as ArrayType, token))
            ptrDecl := VariableDecl new(null, generateTempName("ptrLit"), this, token)
            
            block := Block new(token)
            if(parent instanceOf(VariableDecl)) {
                trail addAfterInScope(vDecl, block)
            } else {
                trail addBeforeInScope(this, block)
            }
            
            block getBody() add(ptrDecl)
            
            declAcc := VariableAccess new(vDecl, token)
            
            innerTypeAcc := VariableAccess new(arrType inner, token)
            copySize := BinaryOp new(arrType expr, VariableAccess new(innerTypeAcc, "size", token), OpTypes mul, token)
            
            memcpyCall := FunctionCall new("memcpy", token)
            memcpyCall args add(VariableAccess new(declAcc, "data", token))
            memcpyCall args add(VariableAccess new(ptrDecl, token))
            memcpyCall args add(copySize)
            block getBody() add(memcpyCall)
            
            type = PointerType new(arrType inner, arrType token)
            
            return Responses LOOP
        }
        
        return Responses OK
        
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        elements replace(oldie, kiddo)
    }

}
