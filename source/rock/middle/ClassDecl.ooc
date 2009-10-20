import structs/ArrayList
import ../frontend/Token
import Expression, Line, Type, Visitor, TypeDecl

ClassDecl: class extends TypeDecl {

    DESTROY_FUNC_NAME   := static const "__destroy__"
    DEFAULTS_FUNC_NAME  := static const "__defaults__"
    LOAD_FUNC_NAME      := static const "__load__"

    isAbstract := false

    init: func ~coverDecl(.name, .superType, .token) { super(name, superType, token) }
    
    accept: func (visitor: Visitor) { visitor visitClassDecl(this) }
    
}

