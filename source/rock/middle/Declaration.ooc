import Expression, VariableDecl

Declaration: abstract class extends Expression {

    init: func ~declaration (.token) { super(token) }

    addTypeArg: func (typeArg: VariableDecl) -> Bool { false }

}
