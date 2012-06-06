import structs/[ArrayList, HashMap]
import ../io/TabbedWriter

import ../frontend/Token
import Expression, Type, Visitor, TypeDecl, Cast, FunctionCall, FunctionDecl,
       Module, Node, VariableDecl, VariableAccess, BinaryOp, Argument,
       Return, CoverDecl, BaseType
import tinker/[Response, Resolver, Trail, Errors]

ClassDecl: class extends TypeDecl {

    DESTROY_FUNC_NAME   := static const "__destroy__"
    LOAD_FUNC_NAME      := static const "__load__"
    DEFAULTS_FUNC_NAME  := static const "__defaults__"

    // for the specializer
    specializations := HashMap<Type, ClassDecl> new()

    // for the specialized
    typeArgMappings: HashMap<String, VariableAccess> {
        get {
            if (isMeta && getNonMeta() instanceOf?(ClassDecl)) {
                getNonMeta() as ClassDecl _typeArgMappings
            } else {
                _typeArgMappings
            }
        }
    }
    _typeArgMappings := HashMap<String, VariableAccess> new()
    specializedSuffix := ""

    isAbstract := false
    isFinal := false
    
    shouldCheckNoArgConstructor := false

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

    hasOtherInit: func -> Bool {
        for(fDecl in functions) if(fDecl getName() == "init") {
            if(fDecl != defaultInit) return true
        }
        false
    }
    
    clone: func -> This {
        cloneWith(|cd|)
    }

    cloneWith: func (prepare: Func(ClassDecl)) -> This {
        copy := This new(name, superType, isMeta, token)
        copy module = module

        typeArgs each(|ta| copy addTypeArg(ta clone()))
        prepare(copy)

        variables each(|k, v| copy addVariable(v clone()))
        
        "==============================" println()
        getMeta() functions each(|f|
            "[special] Adding function %s to %s" printfln(f toString(), copy toString())
            copy getMeta() addFunction(f clone())
        )
        getMeta() getDefaultsFunc()

        copy
    }

    addTypeArg: func (typeArg: VariableDecl) -> Bool {
        if (typeArg getName() == "X") {
            "[special] adding typeArg %s to %s" printfln(typeArg toString(), toString())
        }
        super(typeArg)
    }
    
    underName: func -> String {
        if (isSpecialized() && !isMeta) {
            super() + "__" + specializedSuffix
        } else {
            super()
        }
    }

    hasSpecializations: func -> Bool {
        if (isMeta && getNonMeta() instanceOf?(ClassDecl)) {
            getNonMeta() as ClassDecl hasSpecializations()
        } else {
            !specializations empty?()
        }
    }

    isSpecialized: func -> Bool {
        if (isMeta && getNonMeta() instanceOf?(ClassDecl)) {
            getNonMeta() as ClassDecl isSpecialized()
        } else {
            !typeArgMappings empty?()
        }
    }

    specialize: func (tts: Type) {
        "[special] Specializing %s with %s" printfln(toString(), tts toString())
        ta := tts getTypeArgs()

        if (ta size != typeArgs size) {
            Exception new("[special] Wrong specialization (typeargs count don't match)") throw()
        }

        spe := cloneWith(|copy|
            copy specializedSuffix = generateTempName("specialized")

            "-- Mappings --" println()
            for (i in 0..typeArgs size) {
                lhs := typeArgs get(i)
                rhs := ta get(i)
                "%s => %s" printfln(lhs getName(), rhs toString())
                // Oh, this is unsafe..
                copy typeArgMappings put(lhs getName(), rhs)

                // set refs straight
                "[special] setting type of %s to %s's type" printfln(lhs toString(), rhs toString())
            }
        )
        specializations put(tts, spe)
    }

    resolveType: func (type: BaseType, res: Resolver, trail: Trail) -> Int {
        if (isSpecialized()) {
            "[special] Resolving %s in %s" printfln(type toString(), toString())
            mapped := typeArgMappings get(type getName())
            if (mapped) {
                "[special] Suggesting %s for %s!" printfln(mapped toString(), type toString())
                if (type suggest(mapped getRef())) return 0
            }
        }
        super(type, res, trail)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(shouldCheckNoArgConstructor) {
            finalScore := 0
            if(defaultInit == null || hasOtherInit()) {
                shouldCheckNoArgConstructor = false
            } else {
                if(getSuperRef() == null) superType resolve(trail, res)
                if(getSuperRef() == null) {
                    res wholeAgain(this, "need superRef to check for noarg cons")
                    return Response OK
                } else {
                    superRef := getSuperRef()
                    fDecl := superRef getFunction("init", "", finalScore&)
                    if(finalScore == -1) {
                        res wholeAgain(this, "something not resolved in getFunction")
                        return Response OK
                    }
                    
                    if (fDecl == null || fDecl getArguments() size > 0) {
                        res throwError(NoDefaultConstructorError new(token, "No default no-arg constructor in super-class %s. You need to define a constructor yourself." format(
                            superType getName())))
                    }
                }
            }
        }

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

        finalResponse := Response OK
        specializations each(|k, specialized|
            response := specialized resolve(trail, res)
            if (!response ok()) finalResponse = response

            response  = specialized getMeta() resolve(trail, res)
            if (!response ok()) finalResponse = response
        )

        return finalResponse
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
                shouldCheckNoArgConstructor = true
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

        newType := isMeta ? getNonMeta() getInstanceType() as BaseType : getInstanceType() as BaseType

        constructor := FunctionDecl new("new", fDecl token)
        constructor setStatic(true)
        constructor setSuffix(fDecl getSuffix())
        retType := newType clone() as BaseType
        if(retType getTypeArgs()) retType getTypeArgs() clear()

        constructor getArguments() addAll(fDecl getArguments())
        // [special] TODO: use 'filter' instead? that'd be cleaner
        if(getName() contains?("Glass")) "[special] addInit for %s" printfln(toString())
        getTypeArgs() each (|typeArg|
            if(!typeArgMappings contains?(typeArg getName())) {
                constructor getTypeArgs() add(typeArg)
            }
        )

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

        getTypeArgs() each(|typeArg|
            // assign type arg parameters from the constructor arguments
            // to their member fields
            rhs := VariableAccess new(typeArg, constructor token)
            retType addTypeArg(rhs)

            mapped := typeArgMappings get(typeArg name)
            if (mapped) {
                //rhs = VariableAccess new(VariableAccess new(mapped getName(), mapped token), "class", mapped token)
                rhs = mapped
            }

            thisAccess    := VariableAccess new("this",                   constructor token)
            lhs           := VariableAccess new(thisAccess, typeArg name, constructor token)
            if (mapped) {
                "[special] in %s, doing %s = %s" printfln(toString(), lhs toString(), rhs toString())
            }

            ass := BinaryOp new(lhs, rhs, OpType ass, constructor token)
            constructor getBody() add(ass)
        )

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

    toString: func -> String {
        if (isSpecialized()) {
            super() + " (specialized)"
        } else {
            super()
        }
    }
}

NoDefaultConstructorError: class extends Error {
    init: super func ~tokenMessage
}
