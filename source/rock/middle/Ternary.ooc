import ../frontend/Token
import Expression, Visitor, Type

Ternary: class extends Expression {
    
    condition, ifTrue, ifFalse : Expression

    init: func ~ternary (=condition, =ifTrue, =ifFalse, .token) {
        printf("Got a ternary with condition = %s\n", condition toString())
        printf("  ...ifTrue = %s\n", ifTrue toString())
        printf("and ifFalse = %s\n", ifFalse toString())
        super(token)
    }

    getType: func -> Type {
        // hmm it would probably be good to check that ifTrue and ifFalse have compatible types
        ifTrue getType()
    }
    
    accept: func (visitor: Visitor) {
        visitor visitTernary(this)
    }
    
    toString: func -> String { condition toString() + " ? " + ifTrue toString() + " : " + ifFalse toString() }
    
}
