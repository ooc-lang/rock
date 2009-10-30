import structs/ArrayList
import ../frontend/Token
import Expression, Line, Type, Visitor, TypeDecl

CoverDecl: class extends TypeDecl {
    
    fromType: Type
    
    init: func ~coverDecl(.name, .superType, .token) {
        super(name, superType, token)
        printf("Got CoverDecl %s\n", name)
    }
    
    accept: func (visitor: Visitor) { visitor visitCoverDecl(this) }
    
    setFromType: func (=fromType) {
        printf("CoverDecl %s is now from type %s\n", name, fromType toString())
    }
    
}
