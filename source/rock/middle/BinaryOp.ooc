import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, OperatorDecl,
       Import, Module, FunctionCall
import tinker/[Trail, Resolver, Response]

include stdint

OpType: cover from Int32 {

    toString: func -> String {
        OpTypes repr get(this)
    }
    
}

OpTypes: class {
    add = 1,        /*  +  */
    sub = 2,        /*  -  */
    mul = 3,        /*  *  */
    div = 4,        /*  /  */
    mod = 5,        /*  %  */
    ass = 6,        /*  =  */
    addAss = 7,     /*  += */
    subAss = 8,     /*  -= */
    mulAss = 9,     /*  *= */
    divAss = 10,     /*  /= */
    rshift = 11,    /*  >> */
    lshift = 12,    /*  << */
    rshiftAss = 13, /* >>= */
    lshiftAss = 14, /* <<= */
    bOr = 15,       /*  |  */
    bXor = 16,      /*  ^  */
    bAnd = 17,      /*  &  */
    bOrAss = 18,    /*  |= */
    bXorAss = 19,   /*  ^= */
    bAndAss = 20,   /*  &= */
    or = 21,        /*  || */
    and = 22        /*  && */ : static const OpType
    
    repr := static ["no-op",
        "+",
        "-",
        "*",
        "/",
        "%",
        "=",
        "+=",
        "-=",
        "*=",
        "/=",
        ">>",
        "<<",
        ">>=",
        "<<=",
        "|",
        "^",
        "&",
        "|=",
        "^=",
        "&=",
        "||",
        "&&"] as ArrayList<String>
}

BinaryOp: class extends Expression {

    left, right: Expression
    type: OpType
    
    init: func ~binaryOp (=left, =right, =type, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitBinaryOp(this)
    }
    
    // that's probably not right (haha)
    getType: func -> Type { left getType() }
    
    toString: func -> String {
        return left toString() + " " + OpTypes repr get(type) + " " + right toString()
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        
        {
            response := left resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        {
            response := right resolve(trail, res)
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

        if(type == OpTypes ass) {
            //println("resolving " + toString() + ", right is a " + right class name)
            if(right instanceOf(FunctionCall)) {
                fCall := right as FunctionCall
                fDecl := fCall getRef()
                if(!fDecl) {
                    return Responses LOOP
                }
                if(!fDecl getReturnType() isResolved()) {
                    return Responses LOOP
                }
                
                //println("got assignment rhs a " + fCall toString())
                if(fDecl getReturnType() isGeneric()) {
                    fCall setReturnArg(left)
                    trail peek() replace(this, fCall)
                }
            }
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
            if(score > bestScore) {
                bestScore = score
                candidate = opDecl
            }
        }
        
        for(imp in trail module() getImports()) {
            module := imp getModule()
            for(opDecl in trail module() getOperators()) {
                score := getScore(opDecl, reqType)
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
            fCall getArguments() add(left)
            fCall getArguments() add(right)
            if(!trail peek() replace(this, fCall)) {
                token throwError("Couldn't replace %s with %s!" format(toString(), fCall toString()))
            }
            //return Responses LOOP
            res wholeAgain()
        }
        
        return Responses OK
        
    }
    
    getScore: func (op: OperatorDecl, reqType: Type) -> Int {
        
        symbol := OpTypes repr[type]
        
        if(!(op getSymbol() equals(symbol))) {
            return 0 // not the right overload type - skip
        }
        
        printf("=====\nNot skipped '%s'  vs  '%s'!\n", op getSymbol(), symbol)
        
        fDecl := op getFunctionDecl()
        
        args := fDecl getArguments()
        if(args size() != 2) {
            op token throwError(
                "Argl, you need 2 arguments to override the '%s' operator, not %s" format(symbol, args size()))
        }
        
        score := 0
        
        printf("Reviewing operator %s for %s\n", op toString(), toString())
        printf("Left  score = %d (%s vs %s)\n", args get(0) getType() getScore(left  getType()), args get(0) getType() toString(), left getType() toString())
        printf("Right score = %d (%s vs %s)\n", args get(1) getType() getScore(right getType()), args get(1) getType() toString(), right getType() toString())
        
        score += args get(0) getType() getScore(left getType())
        score += args get(1) getType() getScore(right getType())        
        if(reqType) {
            score += fDecl getReturnType() getScore(reqType)
        }
        
        printf("Final score = %d\n", score)
        
        return score
        
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case left => left = kiddo; true
            case right => right = kiddo; true
            case => false
        }
    }

}
