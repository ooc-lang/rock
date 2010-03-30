import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall, OperatorDecl,
       Import, Module, FunctionCall, ClassDecl, CoverDecl, AddressOf,
       ArrayAccess, VariableAccess, Cast
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
            if(left getType() == null || !left isResolved()) {
                res wholeAgain(this, "left type is unresolved"); return Responses OK
            }
            if(right getType() == null || !right isResolved()) {
                res wholeAgain(this, "right type is unresolved"); return Responses OK
            }
            
            cast : Cast = null
            realRight := right
            if(right instanceOf(Cast)) {
                cast = right as Cast
                realRight = cast inner
            }                
            
            // if we're an assignment from a generic return value
            // we need to set the returnArg to left and disappear! =)
            if(realRight instanceOf(FunctionCall)) {
                fCall := realRight as FunctionCall
                fDecl := fCall getRef()
                if(!fDecl || !fDecl getReturnType() isResolved()) {
                    res wholeAgain(this, "Need more info on fDecl")
                    return Responses OK
                }
                
                if(fDecl getReturnType() isGeneric()) {
                    fCall setReturnArg(left getGenericOperand())
                    trail peek() replace(this, fCall)
                    res wholeAgain(this, "just replaced with fCall and set ourselves as returnArg")
                    return Responses OK
                }
            }
            
            if(isGeneric()) {
                sizeAcc := VariableAccess new(VariableAccess new(left getType() getName(), token), "size", token)

                fCall := FunctionCall new("memcpy", token)
                fCall args add(left  getGenericOperand())
                fCall args add(right getGenericOperand())
                fCall args add(sizeAcc)
                result := trail peek() replace(this, fCall)
                
                if(!result) {
                    if(res fatal) token throwError("Couldn't replace ourselves (%s) with a memcpy/assignment in a %s! trail = %s" format(toString(), trail peek() as Node class name, trail toString()))
                }
                
                res wholeAgain(this, "Replaced ourselves, need to tidy up")
                return Responses OK
            }
        }
        
        if(!isLegal(res)) {
            if(res fatal) {
                token throwError("Invalid use of operator %s between operands of type %s and %s\n" format(
                    OpTypes repr get(type), left getType() toString(), right getType() toString()))
            }
            res wholeAgain(this, "Illegal use, looping in hope.")
        }
                
        return Responses OK
        
    }
    
    isGeneric: func -> Bool {
        (left  getType() isGeneric() && left  getType() pointerLevel() == 0) ||
        (right getType() isGeneric() && right getType() pointerLevel() == 0)
    }
    
    isLegal: func (res: Resolver) -> Bool {
        if(left getType() == null || left getType() getRef() == null || right getType() == null || right getType() getRef() == null) {
            // must resolve first
            res wholeAgain(this, "Unresolved types, looping to determine legitness left = %s (who is null? %s, %s, %s, %s)" format(
              left toString(),
             (left getType() == null) as Bool toString(),
             (left getType() != null && left getType() getRef() == null) as Bool toString(),
             (right getType() == null) as Bool toString(),
             (right getType() != null && right getType() getRef() == null) as Bool toString()))
            return true
        }
        if(left getType() getName() == "Pointer" || right getType() getName() == "Pointer") {
            // pointer arithmetic: you can add, subtract, and assign pointers
            return (type == OpTypes add ||
                    type == OpTypes sub ||
                    type == OpTypes addAss ||
                    type == OpTypes subAss ||
                    type == OpTypes ass)
        }
        if(left getType() getRef() instanceOf(ClassDecl) ||
           right getType() getRef() instanceOf(ClassDecl)) {
            // you can only assign - all others must be overloaded
            return (type == OpTypes ass)
        }
        if((left  getType() getRef() instanceOf(CoverDecl) &&
            left  getType() getRef() as CoverDecl getFromType() == null) ||
           (right getType() getRef() instanceOf(CoverDecl) &&
            right getType() getRef() as CoverDecl getFromType() == null)) {
            // you can only assign structs, others must be overloaded
            return (type == OpTypes ass)
        }
        return true
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
                res wholeAgain(this, "failed to replace oneself, gotta try again =)")
                return Responses OK
                //return Responses LOOP
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
                half = true
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
