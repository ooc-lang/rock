import structs/ArrayList
import ../io/TabbedWriter

import ../frontend/Token
import Expression, Type, Visitor, TypeDecl, Cast, FunctionCall, FunctionDecl,
       Module, Node, VariableDecl, VariableAccess, BinaryOp, Argument,
       Return, CoverDecl, BaseType, AddressOf
import tinker/[Response, Resolver, Trail, Errors]

ClassDecl: class extends TypeDecl {

    DESTROY_FUNC_NAME   := static const "__destroy__"
    LOAD_FUNC_NAME      := static const "__load__"
    DEFAULTS_FUNC_NAME  := static const "__defaults__"
    COVER_DEFAULTS_FUNC_NAME  := static const "__cover_defaults__"

    isAbstract := false
    isFinal := false
    
    shouldCheckNoArgConstructor := false
    isInitReported := false

    init: func ~classDeclNoSuper(.name, .token) {
        super(name, token)
    }

    init: func ~classDeclNotMeta(.name, .superType, .token) {
        init(name, superType, false, token)
    }

    init: func ~classDecl(.name, .superType, =isMeta, .token) {
        super(name, superType, token)
    }

    isAbstract: func -> Bool { isAbstract }

    byRef?: func -> Bool { false }

    accept: func (visitor: Visitor) { visitor visitClassDecl(this) }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(isMeta) {
            meat := getNonMeta()
            isClass := meat class == ClassDecl
            isCover := meat class == CoverDecl
            isCompoundCover := isCover && meat as CoverDecl fromType == null

            if(isClass) {
                if(!functions contains?(This DEFAULTS_FUNC_NAME)) {
                    addFunction(FunctionDecl new(This DEFAULTS_FUNC_NAME, token))
                }
            } else if (isCompoundCover) {
                if(!functions contains?(This COVER_DEFAULTS_FUNC_NAME)) {
                    fDecl := FunctionDecl new(This COVER_DEFAULTS_FUNC_NAME, token)
                    fDecl isThisRef = true
                    fDecl isFinal = true
                    addFunction(fDecl)
                }
            }

            if(!isInitReported && isCover) {
                initDecl := functions get("init")
                if(initDecl && !initDecl isThisRef && !initDecl isExtern){
                    isInitReported = true
                    res throwError(Warning new(initDecl token, "init in cover is non-ref."))
                }
            }

            if(isClass || isCover) {
                if(!functions contains?(This LOAD_FUNC_NAME)) {
                    fDecl := FunctionDecl new(This LOAD_FUNC_NAME, token)
                    fDecl setStatic(true)
                    addFunction(fDecl)
                }
            }
        }

        {
            response := super(trail, res)
            if (!response ok()) return response
        }

        return Response OK
    }

    writeSize: func (w: TabbedWriter, instance: Bool) {
        if(instance) {
            w app("sizeof("). app(underName()). app(')')
        } else {
            w app("sizeof(void*)") // objects are references in ooc
        }
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

    
    getBaseClass: func ~afterResolve(fDecl: FunctionDecl) -> ClassDecl {
        b: Bool
        getBaseClass(fDecl, false, b&)
    }

    getBaseClass: func ~noInterfaces (fDecl: FunctionDecl, comeBack: Bool*) -> ClassDecl {
        getBaseClass(fDecl, false, comeBack)
    }

    getBaseClass: func (fDecl: FunctionDecl, withInterfaces: Bool, comeBack: Bool*) -> ClassDecl {
        sRef := getSuperRef() as ClassDecl
        // An interface might not yet be resolved.
        comeBack@ = false 
        // first look in the supertype, if any
        if(sRef != null) {
             
            base := sRef getBaseClass(fDecl, comeBack)
            if (comeBack@) { // ugly_
                return null
            }
            if(base != null) {
                return base
            }
        }

        // look in interface types, if any
        if(withInterfaces && getNonMeta()) for(interfaceType in getNonMeta() interfaceTypes) {
            iRef := interfaceType getRef() as ClassDecl // missing interface
            if (!iRef) { // ugly_
                comeBack=true
                return null
            }

            if(!iRef isMeta) iRef = iRef getMeta()
            if(iRef != null) {
                base := iRef getBaseClass(fDecl, comeBack)
                if (comeBack) { // ugly_
                    comeBack=true
                    return null
                }
                if(base != null) {
                    return base
                }
            }
        }

        // if all else fails, try in this
        finalScore := 0
        if(getFunction(fDecl name, fDecl suffix ? fDecl suffix : "", null, false, finalScore&) != null) {
            return this
        }

        return null
    }

    replace: func (oldie, kiddo: Node) -> Bool { false }

    addFunction: func (fDecl: FunctionDecl) {

        if(isMeta) {
            if (fDecl getName() == "init" && !fDecl isExternWithName()) {
                /*
                 * init functions generate static new functions so that
                 * objects can be created like:
                 * dog := Dog new()
                 */
                if(!fDecl isSuper) {
                    // don't add super-funcs, because they don't have their complete
                    // signature yet. They will be re-added later
                    addInit(fDecl)
                }
            } else if (fDecl getName() == "new") {
                /*
                 * ..but you can also define the new function yourself,
                 * e.g. if you allocate in a special way
                 */
                already := lookupFunction(fDecl getName(), fDecl getSuffixOrEmpty())
                if (already != null) removeFunction(fDecl)
            }
        }

        super(fDecl)

    }

    addInit: func(fDecl: FunctionDecl) {

        isCover := (getNonMeta() instanceOf?(CoverDecl))
        isCompoundCover := isCover && getNonMeta() as CoverDecl fromType == null

        if(isAbstract || (getNonMeta() instanceOf?(ClassDecl) && getNonMeta() as ClassDecl isAbstract)) {
            // don't generate new for abstract classes
            return
        }

        newType := (isMeta ? getNonMeta() getInstanceType() : getInstanceType()) as BaseType

        constructor := FunctionDecl new("new", fDecl token)
        constructor autoNew = true
        constructor setStatic(true)
        constructor setSuffix(fDecl getSuffix())
        retType := newType clone()

        // FIXME: Why is that needed?
        retType setRef(newType getRef())

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
            vdfe = VariableDecl new(retType, "this", fDecl token)
        }
        constructor getBody() add(vdfe)

        for (typeArg in getTypeArgs()) {
            e := TypeAccess new(typeArg, constructor token)
            retType addTypeArg(e)

            thisAccess    := VariableAccess new("this",                   constructor token)
            typeArgAccess := VariableAccess new(thisAccess, typeArg name, constructor token)
            ass := BinaryOp new(typeArgAccess, e, OpType ass, constructor token)
            constructor getBody() add(ass)
        }

        constructor setReturnType(retType)

        thisAccess := VariableAccess new(vdfe, fDecl token)
        thisAccess setRef(vdfe)

        if(!isCover) {
            defaultsCall := FunctionCall new(DEFAULTS_FUNC_NAME, fDecl token)
            constructor getBody() add(defaultsCall)
        } else if(isCompoundCover){
            defaultsCall := FunctionCall new(COVER_DEFAULTS_FUNC_NAME, fDecl token)
            defaultsCall expr = VariableAccess new(vdfe, fDecl token)
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

NoDefaultConstructorError: class extends Error {
    init: super func ~tokenMessage
}
