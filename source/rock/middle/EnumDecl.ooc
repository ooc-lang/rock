import TypeDecl, Visitor, Node

EnumDecl: class extends TypeDecl {
    init: func ~enumDeclNoSuper(.name, .token) {
        init(name, null, token)
    }
    
    init: func ~enumDecl(.name, .superType, .token) {
        super(name, superType, token)
    }

    accept: func (visitor: Visitor) { visitor visitEnumDecl(this) }

    replace: func (oldie, kiddo: Node) -> Bool { false }
}
