import structs/ArrayList

import ../frontend/Token
import Expression, Type, Visitor, TypeDecl, Cast, FunctionCall, FunctionDecl,
	   Module, Node, VariableDecl, VariableAccess, BinaryOp, Argument,
       Return, CoverDecl
import tinker/[Response, Resolver, Trail]

ClassDecl: class extends TypeDecl {

    DESTROY_FUNC_NAME   := static const "__destroy__"
    DEFAULTS_FUNC_NAME  := static const "__defaults__"
    LOAD_FUNC_NAME      := static const "__load__"

    isAbstract := false
    isFinal := false

    defaultInit := null as FunctionDecl
    
    init: func ~classDeclNoSuper(.name, .token) {
        super(name, token)
    }
    
    init: func ~classDeclNotMeta(.name, .superType, .token) {
        init(name, superType, false, token)
    }

    init: func ~classDecl(.name, .superType, =isMeta, .token) {
        super(name, superType, token)
    }
    
    accept: func (visitor: Visitor) { visitor visitClassDecl(this) }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {

        shouldLoad := false
    	shouldDefault := false
	    for(vDecl in variables) {
			if(vDecl getExpr() != null) {
                if(vDecl isStatic()) {
                    shouldLoad = true
                } else {
                    shouldDefault = true
                }
                if(shouldLoad && shouldDefault) break
			}
	    }
        
        // TODO: a more elegant solution maybe?
        meat : ClassDecl = isMeta ? this : getMeta()
        if(shouldDefault && !meat functions contains(This DEFAULTS_FUNC_NAME)) {
			addFunction(FunctionDecl new(This DEFAULTS_FUNC_NAME, token))
	    }
        if(shouldLoad && !meat functions contains(This LOAD_FUNC_NAME)) {
            fDecl := FunctionDecl new(This LOAD_FUNC_NAME, token)
            fDecl setStatic(true)
			addFunction(fDecl)
	    }
    
        {
            response := super(trail, res)
            if(!response ok()) return response
        }
        
        return Responses OK
    }
    
    getLoadFunc: func -> FunctionDecl {
        // TODO: a more elegant solution maybe?
        meat : ClassDecl = isMeta ? this : getMeta()
        fDecl := meat functions get(This LOAD_FUNC_NAME)
        if(fDecl == null) {
            fDecl = FunctionDecl new(This LOAD_FUNC_NAME, token)
            addFunction(fDecl)
        }
        return fDecl
    }
    
    getDefaultsFunc: func -> FunctionDecl {
        // TODO: a more elegant solution maybe?
        meat : ClassDecl = isMeta ? this : getMeta()
        fDecl := meat functions get(This DEFAULTS_FUNC_NAME)
        if(fDecl == null) {
            fDecl = FunctionDecl new(This DEFAULTS_FUNC_NAME, token)
            addFunction(fDecl)
        }
        return fDecl
    }
    
    getBaseClass: func (fDecl: FunctionDecl) -> ClassDecl {
        sRef : ClassDecl  = getSuperRef()
		if(sRef != null) {
			base := sRef getBaseClass(fDecl)
			if(base != null) {
                return base
            }
		}
        finalScore : Int
		if(getFunction(fDecl name, fDecl suffix, null, false, finalScore&) != null) return this
		return null
	}
    
    replace: func (oldie, kiddo: Node) -> Bool { false }

	addDefaultInit: func {
        
        if(!isMeta) {
            getMeta() addDefaultInit()
            return
        }
        
		if(!isAbstract && !isObjectClass() && !isClassClass() && defaultInit == null) {
            /*
             * Concrete classes that aren't `Object` nor `Class` get a
             * default, no-args constructor that does nothing.
             * It gets removed as soon as you add another init() function
             * though, see addInit()
             */
            init := FunctionDecl new("init", token)
			addFunction(init)
            defaultInit = init // if defaultInit is set earlier, it'll try to remove it..
        }
	}

    addFunction: func (fDecl: FunctionDecl) {
        
        if(isMeta) {
            if (fDecl getName() == "init" && !fDecl isExternWithName()) {
                /*
                 * init functions generate static new functions so that
                 * objects can be created like:
                 * dog := Dog new()
                 */
                addInit(fDecl)
            } else if (fDecl getName() == "new") {
                /*
                 * ..but you can also define the new function yourself,
                 * e.g. if you allocate in a special way
                 */
                already := lookupFunction(fDecl getName(), fDecl getSuffix())
                if (already != null) removeFunction(fDecl) 
            }
        }
	
		super(fDecl)
        
    }

	addInit: func(fDecl: FunctionDecl) {
        
        isCover := (getNonMeta() instanceOf(CoverDecl))
        
		if(defaultInit != null) {
            /*
             * As soon as we've got another init defined, remove the
             * default, no-args, empty one.
             */
            functions remove(hashName("init", null))
            functions remove(hashName("new", null))
            defaultInit = null
        }
		
        newType := getNonMeta() getInstanceType() as BaseType
        
		constructor := FunctionDecl new("new", fDecl token)
        constructor setStatic(true)
		constructor setSuffix(fDecl getSuffix())
		retType := newType clone() as BaseType
		if(retType getTypeArgs()) retType getTypeArgs() clear()
		
		constructor getArguments() addAll(fDecl getArguments())
		constructor getTypeArgs() addAll(getTypeArgs())
		
        // why use getNonMeta() here? addInit() is called only in the
        // meta-class, remember?
        newTypeAccess := VariableAccess new(newType, fDecl token)
        newTypeAccess setRef(getNonMeta())
        
        vdfe : VariableDecl = null
        if(!isCover) {
            allocCall := FunctionCall new(newTypeAccess, "alloc", fDecl token)
            expr := Cast new(allocCall, newType, fDecl token)
            vdfe = VariableDecl new(null, "this", expr, fDecl token)
        } else {
            vdfe = VariableDecl new(newType clone(), "this", fDecl token)
        }
        constructor getBody() add(vdfe)
		
        for (typeArg in getTypeArgs()) {
        	e := VariableAccess new(typeArg getName(), constructor token)
			retType addTypeArg(e)
			
            thisAccess    := VariableAccess new("this",                   constructor token)
            typeArgAccess := VariableAccess new(thisAccess, typeArg name, constructor token)
            ass := BinaryOp new(typeArgAccess, e, OpTypes ass, constructor token)
			constructor getBody() add(ass)
		}
        
		constructor setReturnType(retType)
		
		thisAccess := VariableAccess new(vdfe, fDecl token)
		thisAccess setRef(vdfe)
		
        if(!isCover) {
            defaultsCall := FunctionCall new("__defaults__", fDecl token)
            constructor getBody() add(defaultsCall)
        }
        
        initCall := FunctionCall new(fDecl getName(), fDecl token)
        initCall setSuffix(fDecl getSuffix())
        initCall setExpr(VariableAccess new(vdfe, fDecl token))
		for (arg in constructor getArguments()) {
			initCall getArguments() add(VariableAccess new(arg, fDecl token))
		}
		constructor getBody() add(initCall)
		constructor getBody() add(Return new(thisAccess, fDecl token))
		
		addFunction(constructor)	
	}
}

