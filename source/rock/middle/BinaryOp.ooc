import structs/ArrayList
import ../frontend/Token
import Expression, Visitor

OpType: class {
    add = 1, // +
    sub = 2, // -
    mul = 3, // *
    div = 4, // /
    addAss = 5, // +=
    subAss = 6, // -=
    mulAss = 7, // *=
    divAss = 8 : static const Int32 // /=
    
    repr := static ["no-op", "+", "-", "*", "/", "+=", "-=", "*=", "/="] as ArrayList<String>
}

BinaryOp: class extends Expression {

    left, right: Expression
    type: Int32
    
    init: func ~add (=left, =right, =type, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitBinaryOp(this)
    }

}
