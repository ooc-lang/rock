import structs/ArrayList
import Node, Type, Declaration, Expression, Visitor

Atom: class {
    name: String
    expr: Expression
    
    init: func ~n (=name) {}
    init: func ~ne (=name, =expr) {}
}

VariableDecl: class extends Declaration {

    type: Type
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
