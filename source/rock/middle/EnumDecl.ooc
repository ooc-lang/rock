import TypeDecl, Visitor, Node, IntLiteral

EnumDecl: class extends TypeDecl {
    lastElementValue: Int64 = 0

    init: func ~enumDeclNoSuper(.name, .token) {
        super(name, null, token)
    }

    getNextElementValue: func -> Int64 {
        lastElementValue += 1
        return lastElementValue
    }

    setLastElementValue: func (value: Int64) { lastElementValue = value }

    accept: func (visitor: Visitor) { visitor visitEnumDecl(this) }

    replace: func (oldie, kiddo: Node) -> Bool { false }
}
