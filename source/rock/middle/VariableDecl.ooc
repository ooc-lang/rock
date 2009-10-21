import structs/ArrayList
import Node, Type, Declaration, Expression, Visitor

Atom: class {
    name: String
    expr: Expression
    
    init: func ~name (=name) {}
    init: func ~nameExpr (=name, =expr) {}
}

VariableDecl: class extends Declaration {

    type: Type
    isStatic := false
    isExtern := false
    atoms := ArrayList<Atom> new()
    
    init: func ~vDecl (=type, .token) {
        super(token)
    }
    
    init: func ~vDeclWithAtom (=type, atom: Atom, .token) {
        super(token)
        atoms add(atom)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitVariableDecl(this)
    }

}
