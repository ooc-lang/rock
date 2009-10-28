import structs/ArrayList
import ../frontend/Token
import Expression, Line, Type, Visitor, TypeDecl

CoverDecl: class extends TypeDecl {
    
    fromType: Type
    
    init: func ~coverDecl(.name, .superType, .token) { super(name, superType, token) }
    
    accept: func (visitor: Visitor) { visitor visitCoverDecl(this) }
    
}
