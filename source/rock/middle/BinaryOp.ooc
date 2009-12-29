import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type, Node, FunctionCall
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
    and = 22,       /*  && */
    incr = 23,      /*  ++ */
    decr = 24       /*  -- */ : static const OpType
    
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
        "&&",
        "++",
        "--"] as ArrayList<String>
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

        if(type == OpTypes ass) {
            println("resolving " + toString() + ", right is a " + right class name)
            if(right instanceOf(FunctionCall)) {
                fCall := right as FunctionCall
                println("got assignment rhs a " + fCall toString())
                fCall setReturnArg(left)
                trail peek() replace(this, fCall)
            }
        }
        
        return Responses OK
        
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case left => left = kiddo; true
            case right => right = kiddo; true
            case => false
        }
    }

}
