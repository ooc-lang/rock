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
    
    init: func ~variableDecl (=type, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitVariableDecl(this)
    }

}
