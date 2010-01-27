import structs/ArrayList

import ../frontend/Token
import Expression, Type, Visitor, TypeDecl, Cast, FunctionCall, FunctionDecl,
	   Module, Node, VariableDecl, VariableAccess, BinaryOp, Argument, Return
import tinker/[Response, Resolver, Trail]

ClassDecl: class extends TypeDecl {

    DESTROY_FUNC_NAME   := static const "__destroy__"
    DEFAULTS_FUNC_NAME  := static const "__defaults__"
    LOAD_FUNC_NAME      := static const "__load__"

    isAbstract := false
    isFinal := false
    
    init: func ~classDeclNoSuper(.name, .token) {
        super(name, token)
    }
    
    init: func ~classDeclNotMeta(.name, .superType, .token) {
        this(name, superType, false, token)
    }

    init: func ~classDecl(.name, .superType, =isMeta, .token) {
        super(name, superType, token)
    }
    
    accept: func (visitor: Visitor) { visitor visitClassDecl(this) }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        {
            response := super resolve(trail, res)
            if(!response ok()) return response
        }
        
        return Responses OK
    }
    
    getBaseClass: func (fDecl: FunctionDecl) -> ClassDecl {
        sRef : ClassDecl  = getSuperRef()
		if(sRef != null) {
			base := sRef getBaseClass(fDecl)
			if(base != null) {
                return base
            }
		}
		if(getFunction(fDecl name, fDecl suffix, null, false) != null) return this
		return null
	}
    
    replace: func (oldie, kiddo: Node) -> Bool { false }

    addFunction: func (fDecl: FunctionDecl) {
        
        if(isMeta) {
            if (fDecl getName() == "init") {
                addInit(fDecl)
            } else if (fDecl getName() == "new") {
                already := getFunction(fDecl getName(), fDecl getSuffix())
                // FIXME, just removing based off fDecl name for now
                if (already != null) removeFunction(fDecl) 
            }
        }
	
		super addFunction(fDecl)
        
    }

	addInit: func(fDecl: FunctionDecl) {
		/* if defaultInit != null */
		
        newType := getNonMeta() getInstanceType()
        
		constructor := FunctionDecl new("new", fDecl token)
        constructor setStatic(true)
		constructor setSuffix(fDecl getSuffix())
		retType := newType clone()
		retType getTypeArgs() clear()
		
		constructor getArguments() addAll(fDecl getArguments())
		constructor getTypeArgs() addAll(getTypeArgs())
		
        // why use getNonMeta() here? addInit() is called only in the
        // meta-class, remember?
        newTypeAccess := VariableAccess new(newType, fDecl token)
        newTypeAccess setRef(getNonMeta())
        allocCall := FunctionCall new(newTypeAccess, "alloc", fDecl token)
		cast := Cast new(allocCall, newType, fDecl token)
		vdfe := VariableDecl new(null, "this", cast, fDecl token)
		constructor getBody() add(vdfe)
		
        /*
		for (typeArg in typeArgs) {
			e := VariableAccess new(typeArg getName(), constructor token)
			retType getTypeArgs() add(e)
			
			constructor getBody() add(BinaryOp new(VariableAccess new(VariableAccess new("this", constructor token), typeArg name, constructor token), e, OpTypes ass, constructor token))		
		}
        */
		constructor setReturnType(retType)
		
		thisAccess := VariableAccess new(vdfe, fDecl token)
		thisAccess setRef(vdfe)
		
        // TODO: add suffix handling
		initCall := FunctionCall new(fDecl getName(), fDecl token)
        initCall setExpr(VariableAccess new("this", fDecl token))
		for (arg in constructor getArguments()) {
			initCall getArguments() add(VariableAccess new(arg, fDecl token))
		}
		constructor getBody() add(initCall)
		constructor getBody() add(Return new(thisAccess, fDecl token))
		
		addFunction(constructor)	
	}
}

