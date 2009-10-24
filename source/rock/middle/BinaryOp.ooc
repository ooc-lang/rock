import structs/ArrayList
import ../frontend/Token
import Expression, Visitor, Type

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
    addAss = 5,     /*  += */
    subAss = 6,     /*  -= */
    mulAss = 7,     /*  *= */
    divAss = 8,     /*  /= */
    rshift = 9,     /*  >> */
    lshift = 10,    /*  << */
    rshiftAss = 11, /* >>= */
    lshiftAss = 12, /* <<= */
    bOr = 13,       /*  |  */
    bXor = 14,      /*  ^  */
    bAnd = 15,      /*  &  */
    bOrAss = 16,    /*  |= */
    bXorAss = 17,   /*  ^= */
    bAndAss = 18,   /*  &= */
    or = 19,        /*  || */
    and = 20,       /*  && */
    incr = 21,      /*  ++ */
    decr = 22       /*  -- */ : static const OpType
    
    repr := static ["no-op",
        "+",
        "-",
        "*",
        "/",
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
    
    init: func ~add (=left, =right, =type, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitBinaryOp(this)
    }
    
    // that's probably not right (haha)
    getType: func -> Type { left getType() }

}
