import structs/ArrayList
import ../io/TabbedWriter

import ../frontend/Token
import Expression, Type, Visitor, TypeDecl, Cast, FunctionCall, FunctionDecl,
       Module, Node, VariableDecl, VariableAccess, BinaryOp, Argument,
       Return, CoverDecl, BaseType
import tinker/[Response, Resolver, Trail]

ClassDecl: class extends TypeDecl {

    DESTROY_FUNC_NAME   := static const "__destroy__"
    LOAD_FUNC_NAME      := static const "__load__"
    DEFAULTS_FUNC_NAME  := static const "__defaults__"

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

    isAbstract: func -> Bool { isAbstract }

    byRef?: func -> Bool { false }

    accept: func (visitor: Visitor) { visitor visitClassDecl(this) }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(isMeta) {
            if(getNonMeta() class == ClassDecl) {
                if(!functions contains?(This DEFAULTS_FUNC_NAME)) {
                    addFunction(FunctionDecl new(This DEFAULTS_FUNC_NAME, token))
                }
            }
            if(getNonMeta() class == ClassDecl || getNonMeta() class == CoverDecl) {
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

    getBaseClass: func ~noInterfaces (fDecl: FunctionDecl) -> ClassDecl {
        getBaseClass(fDecl, false)
    }

    getBaseClass: func (fDecl: FunctionDecl, withInterfaces: Bool) -> ClassDecl {
        sRef := getSuperRef() as ClassDecl

        // first look in the supertype, if any
        if(sRef != null) {
            base := sRef getBaseClass(fDecl)
            if(base != null) {
                return base
            }
        }

        // look in interface types, if any
        if(withInterfaces && getNonMeta()) for(interfaceType in getNonMeta() interfaceTypes) {
            iRef := interfaceType getRef() as ClassDecl
            if(!iRef isMeta) iRef = iRef getMeta()
            if(iRef != null) {
                base := iRef getBaseClass(fDecl)
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

            // TODO: check if the super-type actually has a no-arg constructor, throw an error if not
            if(superType != null && superType getName() != "ClassClass") {
                init getBody() add(FunctionCall new("super", token))
            }

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
                already := lookupFunction(fDecl getName(), fDecl getSuffix())
                if (already != null) removeFunction(fDecl)
            }
        }

        super(fDecl)

    }

    addInit: func(fDecl: FunctionDecl) {

        isCover := (getNonMeta() instanceOf?(CoverDecl))

        if(defaultInit != null) {
            /*
             * As soon as we've got another init defined, remove the
             * default, no-args, empty one.
             */
            functions remove(hashName("init", null))
            functions remove(hashName("new", null))
            defaultInit = null
        }

        if(isAbstract || (getNonMeta() instanceOf?(ClassDecl) && getNonMeta() as ClassDecl isAbstract)) {
            // don't generate new for abstract classes
            return
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
            e := VariableAccess new(typeArg, constructor token)
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

