import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, OperatorDecl,
       Import, Module, FunctionCall
import tinker/[Trail, Resolver, Response]

include stdint

OpType: cover from Int8 {

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
    rshift = 6,     /*  >> */
    lshift = 7,     /*  << */
    bOr = 8,        /*  |  */
    bXor = 9,       /*  ^  */
    bAnd = 10,      /*  &  */
    
    ass = 11,       /*  =  */
    
    addAss = 12,    /*  += */
    subAss = 13,    /*  -= */
    mulAss = 14,    /*  *= */
    divAss = 15,    /*  /= */
    rshiftAss = 16, /* >>= */
    lshiftAss = 17, /* <<= */
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
        ">>",
        "<<",
        "|",
        "^",
        "&",
        
        "=",
        "+=",
        "-=",
        "*=",
        "/=",
        ">>=",
        "<<=",
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
    
    isAssign: func -> Bool { (type >= OpTypes ass) && (type <= OpTypes bAndAss) }
    
    accept: func (visitor: Visitor) {
        visitor visitBinaryOp(this)
    }
    
    // that's probably not right (haha)
    getType: func -> Type { left getType() }
    getLeft:  func -> Expression { left  }
    getRight: func -> Expression { right }
    
    toString: func -> String {
        return left toString() + " " + OpTypes repr get(type) + " " + right toString()
    }
    
    unwrapAssign: func (trail: Trail, res: Resolver) -> Bool {
        
        if(!isAssign()) return false
        
        innerType := type - (OpTypes addAss - OpTypes add)
        inner := BinaryOp new(left, right, innerType, token)
        right = inner
        type = OpTypes ass
        
        return true
        
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
            // if we're an assignment from a generic return value
            // we need to set the returnArg to left and disappear! =)
            if(right instanceOf(FunctionCall)) {
                fCall := right as FunctionCall
                fDecl := fCall getRef()
                if(!fDecl) {
                    return Responses LOOP
                }
                if(!fDecl getReturnType() isResolved()) {
                    return Responses LOOP
                }
                
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
            if(score == -1) { res wholeAgain(this, "score of %s == -1 !!" format(opDecl toString())); return Responses OK }
            if(score > bestScore) {
                bestScore = score
                candidate = opDecl
            }
        }
        
        for(imp in trail module() getImports()) {
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
            if(isAssign() && !candidate getSymbol() endsWith("=")) {
                // we need to unwrap first!
                unwrapAssign(trail, res)
                trail push(this)
                right resolve(trail, res)
                trail pop(this)
                return Responses OK
            }
            
            fDecl := candidate getFunctionDecl()
            fCall := FunctionCall new(fDecl getName(), token)
            fCall setRef(fDecl)
            fCall getArguments() add(left)
            fCall getArguments() add(right)
            if(!trail peek() replace(this, fCall)) {
                if(res fatal) token throwError("Couldn't replace %s with %s! trail = %s" format(toString(), fCall toString(), trail toString()))
                return Responses LOOP
            }
            res wholeAgain(this, "Just replaced with an operator overloading")
        }
        
        return Responses OK
        
    }
    
    getScore: func (op: OperatorDecl, reqType: Type) -> Int {
        
        symbol : String = OpTypes repr[type]
        
        half := false
        
        if(!(op getSymbol() equals(symbol))) {
            if(isAssign() && symbol startsWith(op getSymbol())) {
                // alright!
            } else {
                return 0 // not the right overload type - skip
            }
        }
        
        fDecl := op getFunctionDecl()
        
        args := fDecl getArguments()
        if(args size() != 2) {
            op token throwError(
                "Argl, you need 2 arguments to override the '%s' operator, not %d" format(symbol, args size()))
        }
        
        score := 0
        
        opLeft  := args get(0)
        opRight := args get(1)
        
        if(opLeft getType() == null || opRight getType() == null || left getType() == null || right getType() == null) {
            return -1
        }
        
        score += opLeft  getType() getScore(left getType())
        score += opRight getType() getScore(right getType())        
        if(reqType) {
            score += fDecl getReturnType() getScore(reqType)
        }
        if(half) {
            score /= 2
        }
        
        return score
        
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case left  => left  = kiddo; true
            case right => right = kiddo; true
            case => false
        }
    }

}
