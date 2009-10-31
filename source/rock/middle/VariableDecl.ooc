import structs/ArrayList
import Node, Type, Declaration, Expression, Visitor, TypeDecl

VariableDecl: class extends Declaration {

    name: String
    type: Type
    expr: Expression
    owner: TypeDecl
    
    isStatic := false
    isExtern := false
    
    init: func ~vDecl (.type, .name, .token) {
        this(type, name, null, token)
    }
    
    init: func ~vDeclWithAtom (=type, =name, =expr, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitVariableDecl(this)
    }
    
    getType: func -> Type { type }
    
    toString: func -> String {
        name + ": " + type toString()
    }

}
