import structs/ArrayList

import ../frontend/Token
import Expression, Type, Visitor, TypeDecl, FunctionDecl,
       FunctionCall, Module, Node
import tinker/[Response, Resolver, Trail]

ClassDecl: class extends TypeDecl {

    DESTROY_FUNC_NAME   := static const "__destroy__"
    DEFAULTS_FUNC_NAME  := static const "__defaults__"
    LOAD_FUNC_NAME      := static const "__load__"

    isAbstract := false
    isFinal := false
    
    meta : ClassDecl = null
    nonMeta : ClassDecl = null

    init: func ~classDeclNotMeta(.name, .superType, .token) {
        this(name, superType, false, token)
    }

    init: func ~classDecl(.name, .superType, =isMeta, .token) {
        super(name clone(), superType, token)

        if(!superType && !isObjectClass()) {
            // everyone inherits from object, darling.
            this superType = BaseType new("Object", token)
        }
        
        if(!this isMeta) {
            // create the meta-class
            metaSuperType : Type = null
            if(this superType) {
                metaSuperType = BaseType new(this superType getName() + "Class", nullToken)
            } else {
                metaSuperType = BaseType new("Class", nullToken)
            }
            meta = ClassDecl new(name + "Class", metaSuperType, true, token)
            meta nonMeta = this
            meta thisDecl = this thisDecl
            
            // if we access to "Dog", we access to an object of type "DogClass"
            type = meta getInstanceType()
            type as BaseType ref = meta
        }
    }
    
    accept: func (visitor: Visitor) { visitor visitClassDecl(this) }
    
    addFunction: func (fDecl: FunctionDecl) {
        //printf("______**** ClassDecl %s just got function %s isMeta? %s\n", name, fDecl toString(), isMeta toString())
        if(!isMeta) {
            meta addFunction(fDecl)
        } else {
            functions put(fDecl name, fDecl)
        }
        fDecl owner = this
    }
    
    isObjectClass: func -> Bool {
        name equals("Object") || name equals("ObjectClass")
    }
    
    isClassClass: func -> Bool {
        name equals("Class") || name equals("ClassClass")
    }
    
    isRootClass: func -> Bool {
        isObjectClass() || isClassClass()
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        {
            response := super resolve(trail, res)
            if(!response ok()) return response
        }
        
        if(meta) {
            trail push(this)
            meta module = module
            module types put(meta name, meta)
            response := meta resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                printf("-- %s, meta of %s, isn't resolved, looping.\n", meta toString(), toString())
                return response
            }
        }
        
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
    
    getMeta: func -> This { meta }
    getNonMeta: func -> This { nonMeta }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
}

