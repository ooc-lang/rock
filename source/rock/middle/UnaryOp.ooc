import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, OperatorDecl
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
        
        {
            response := resolveOverload(trail, res)
            if(!response ok()) return response
        }
        
        return Responses OK
        
    }
    
    resolveOverload: func (trail: Trail, res: Resolver) -> Response {
        
        // so here's the plan: we give each operator overload a score
        // depending on how well it fits our requirements (types)
        
        bestScore := 0
        candidate : OperatorDecl = null
        
        reqType := trail peek() getRequiredType()
        
        for(opDecl in trail module() getOperators()) {
            score := getScore(opDecl, reqType)
            if(score == -1) { res wholeAgain(this, "score of %s == -1 !!" format(opDecl toString())); return Responses OK }
            if(score > bestScore) {
                bestScore = score
                candidate = opDecl
            }
        }
        
        for(imp in trail module() getAllImports()) {
            module := imp getModule()
            for(opDecl in module getOperators()) {
                score := getScore(opDecl, reqType)
                if(score == -1) { res wholeAgain(this, "score of %s == -1 !!" format(opDecl toString())); return Responses OK }
                if(score > bestScore) {
                    bestScore = score
                    candidate = opDecl
                }
            }
        }
        
        if(candidate != null) {
            fDecl := candidate getFunctionDecl()
            fCall := FunctionCall new(fDecl getName(), token)
            fCall setRef(fDecl)
            fCall getArguments() add(inner)
            if(!trail peek() replace(this, fCall)) {
                if(res fatal) token throwError("Couldn't replace %s with %s!" format(toString(), fCall toString()))
                res wholeAgain(this, "failed to replace oneself, gotta try again =)")
                return Responses OK
                //return Responses LOOP
            }
            res wholeAgain(this, "Just replaced with an operator overloading")
        }
        
        return Responses OK
        
    }
    
    getScore: func (op: OperatorDecl, reqType: Type) -> Int {
        
        symbol := UnaryOpTypes repr[type]
        
        if(!(op getSymbol() equals(symbol))) {
            return 0 // not the right overload type - skip
        }
        
        fDecl := op getFunctionDecl()
        
        args := fDecl getArguments()
        
        //if we have 2 arguments, then it's a binary plus binary
        if(args size() == 2) return 0
			
        if(args size() != 1) {
            op token throwError(
                "Argl, you need 1 argument to override the '%s' operator, not %d" format(symbol, args size()))
        }
        
        score := 0
        
        if(args get(0) getType() == null || inner getType() == null) { return -1 }
        
        score += args get(0) getType() getScore(inner getType())
        if(reqType) {
            score += fDecl getReturnType() getScore(reqType)
        }
        
        return score
        
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case inner => inner = kiddo; true
            case => false
        }
    }
    
}
