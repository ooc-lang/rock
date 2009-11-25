import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type
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
    ass = 5,        /*  =  */
    addAss = 6,     /*  += */
    subAss = 7,     /*  -= */
    mulAss = 8,     /*  *= */
    divAss = 9,     /*  /= */
    rshift = 10,    /*  >> */
    lshift = 11,    /*  << */
    rshiftAss = 12, /* >>= */
    lshiftAss = 13, /* <<= */
    bOr = 14,       /*  |  */
    bXor = 15,      /*  ^  */
    bAnd = 16,      /*  &  */
    bOrAss = 17,    /*  |= */
    bXorAss = 18,   /*  ^= */
    bAndAss = 19,   /*  &= */
    or = 20,        /*  || */
    and = 21,       /*  && */
    incr = 22,      /*  ++ */
    decr = 23       /*  -- */ : static const OpType
    
    repr := static ["no-op",
        "+",
        "-",
        "*",
        "/",
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
        return left toString() + OpTypes repr get(type) + right toString()
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
        
        return Responses OK
        
    }

}
