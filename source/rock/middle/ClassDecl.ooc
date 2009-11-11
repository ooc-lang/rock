import structs/ArrayList
import ../frontend/Token
import Expression, Line, Type, Visitor, TypeDecl
import tinker/Response

ClassDecl: class extends TypeDecl {

    DESTROY_FUNC_NAME   := static const "__destroy__"
    DEFAULTS_FUNC_NAME  := static const "__defaults__"
    LOAD_FUNC_NAME      := static const "__load__"

    isAbstract := false
    isFinal := false

    init: func ~classDecl(.name, .superType, .token) {
        super(name clone(), superType, token)
    }
    
    accept: func (visitor: Visitor) { visitor visitClassDecl(this) }
    
    isObjectClass: func -> Bool {
        //name equals("Object")
        true // workaround
    }
    
    isClassClass: func -> Bool {
        name equals("Class")
    }
    
    isRootClass: func -> Bool {
        isObjectClass() || isClassClass()
    }
    
    toString: func -> String {
        class name + ' ' + name
    }
    
    resolve: func -> Response {
        printf("Resolving %s\n", toString())
        return Responses OK
    }
    
}

