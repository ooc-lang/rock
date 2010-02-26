Cell: class {}

expr := Cell new()

VariableAccess: class extends Cell { getRef: func -> Object { this } }
NamespaceDecl: class {}

getVal: func -> Bool {
    (expr != null) &&
    !(expr instanceOf(VariableAccess) &&
      expr as VariableAccess getRef() != null &&
      expr as VariableAccess getRef() instanceOf(NamespaceDecl)
    )
}

main: func {
    getVal() toString() println()
}
