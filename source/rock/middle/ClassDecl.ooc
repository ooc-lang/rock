import structs/ArrayList

import ../frontend/Token
import Expression, Line, Type, Visitor, TypeDecl, FunctionDecl
import tinker/[Response, Resolver, Trail]

ClassDecl: class extends TypeDecl {

    DESTROY_FUNC_NAME   := static const "__destroy__"
    DEFAULTS_FUNC_NAME  := static const "__defaults__"
    LOAD_FUNC_NAME      := static const "__load__"

    isAbstract := false
    isFinal := false
    
    isMeta := false

    init: func ~classDeclNotMeta(.name, .superType, .token) {
        this(name, superType, false, token)
    }

    init: func ~classDecl(.name, .superType, =isMeta, .token) {
        super(name clone(), superType, token)

        if(!superType && !isObjectClass() && !isClassClass()) {
            // everyone inherits from object, biatch.
            this superType = BaseType new("Object", token)
        }
        
        if(!isMeta) {
            // create the meta-class
        }
    }
    
    accept: func (visitor: Visitor) { visitor visitClassDecl(this) }
    
    isObjectClass: func -> Bool {
        name equals("Object")
    }
    
    isClassClass: func -> Bool {
        name equals("Class")
    }
    
    isRootClass: func -> Bool {
        isObjectClass() || isClassClass()
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        response := super resolve(trail, res)
        if(!response ok()) return response
        
        return Responses OK
    }
    
    getBaseClass: func (fDecl: FunctionDecl) -> ClassDecl {
        sRef : ClassDecl  = superRef()
		if(sRef != null) {
			base := sRef getBaseClass(fDecl)
			if(base != null) {
                return base
            }
		}
		if(getFunction(fDecl name, fDecl suffix, null, false) != null) return this
		return null
	}
    
}

