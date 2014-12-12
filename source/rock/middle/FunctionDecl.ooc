import structs/[Stack, ArrayList, List, HashMap]
import ../frontend/[Token, BuildParams, AstBuilder]
import Cast, Expression, Type, Visitor, Argument, TypeDecl, Scope,
       VariableAccess, ControlStatement, Return, IntLiteral, If, Else,
       VariableDecl, Node, Statement, Module, FunctionCall, Declaration,
       Version, StringLiteral, Conditional, Import, ClassDecl, StringLiteral,
       IntLiteral, NullLiteral, BaseType, FuncType, AddressOf, BinaryOp,
       TypeList, CoverDecl, StructLiteral, Dereference, OperatorDecl

import tinker/[Resolver, Response, Trail, Errors]

import algo/autoReturn

/**
   A function declaration.

   A function has a name and optionally a suffix. If the function has
   no suffix, then `suffix` is null.

   The return type is voidType if unspecified, or the type after the '->'
   in the function declaration otherwise.

   A function may have 0 or more arguments. Arguments can be TypeArg(s), as in:

     exit: extern func (Int)

   AssArg (assign arguments):

     init: func (=x, =y) {}

   DotArg (member arguments):

     init: func (.x, .y) { position = Point new(x, y) }

   VarArg (variable argument):

     printf: extern func (fmt: CString, ...)

   Or just regular Argument(s) :

     add: func (element: T) {}

*/
FunctionDecl: class extends Declaration {

    /** The operator declaration this FunctionDecl corresponds to */
    oDecl: OperatorDecl

    isGenerated := false

    /** name: func ~suffix - suffix is null if there's no suffix in the grammar */
    name := ""
    suffix: String

    fullName: String
    doc := ""

    hash: String { get {
        suffix ? "#{name}~#{suffix}" : name
    } }

    prettyName: String { get {
        unbangify(name)
    } }

    /** The return type of this function. If it's generic, or if it's a TypeList, then returnArgs will be used */
    returnType := voidType
    /** For some extreme inference cases, this is the type we can infer from return expression inside the body. See Return */
    inferredReturnType : Type = null

    /**
     * An abstract function is a method of an abtract class that *has*
     * to be implemented by any concrete subclasses of it.
     *
     * Its body is empty, and it doesn't get written, but everything else
     * is as usual.
     */
    isAbstract := false
    isStatic := false
    isInline := false
    isFinal := false
    isProto := false
    isSuper := false
    externName : String = null
    unmangledName: String = null

    /** if true, 'this' has byref semantics */
    isThisRef := false

    /** used to resolve accesses and calls for closures, after they're unwrapped */
    context: Trail = null

    /** internal hack used to ensure resolving of variables inside closure after they're unwrapped */
    countdown := 5

    /** If this FunctionDecl is a shim to make a VariableDecl callable, then vDecl is set to that variable decl. */
    vDecl : VariableDecl = null

    /** generic type args of this function, ie. T in blah: func <T> */
    typeArgs := ArrayList<VariableDecl> new()

    /** arg1, arg2, arg3 in blah: func (arg1: Type, arg2: Type, arg3: Type) */
    args := ArrayList<VariableDecl> new()

    /**
     * invisible arguments used for returning values in a few cases:
     *   - generic return type
     *   - multi-return, ie. blah: func -> (Type, Type, ...)
     */
    returnArgs := ArrayList<VariableDecl> new()

    /** body of the function (list of statements) */
    body := Scope new()
    hasBody := false

    _returnTypeResolvedOnce := false

    partialByReference := ArrayList<VariableDecl> new()
    partialByValue := ArrayList<VariableDecl> new()
    clsAccesses := ArrayList<VariableAccess> new()
    fromClosure := false
    _unwrappedClosure := false
    _unwrappedACS := false

    /**
     * If we are a method (member function), 'owner' is non-null, and is a reference
     * to the TypeDecl to which we belong
     */
    owner : TypeDecl { get set }

    /** If we're a method, staticVariant is the variant where 'this' is an actual explicit argument */
    staticVariant : This = null

    verzion: VersionSpec = null

    /** true if it's an anonymous function, ie. our name is empty on the beginning */
    isAnon: Bool

    /** true if new auto-generated from init */
    autoNew := false

    genericConstraints: HashMap<Type, Type>

    init: func ~funcDecl (=name, .token) {
        super(token)
        this isAnon = name empty?()

        // init functions are final by default - allowing constructors with different
        // signatures in a hierarchy without having to bother with suffixes and without
        // trying to overload constructors
        this isFinal = (name == "init")
    }

    clone: func -> This {
        clone(name)
    }

    clone: func ~withName (name: String) -> This {
        copy := new(name, token)

        copy isAbstract = isAbstract
        copy isStatic = isStatic
        copy isInline = isInline
        copy isFinal = isFinal
        copy isProto = isProto
        copy isSuper = isSuper
        copy externName = externName
        copy unmangledName = unmangledName
        copy suffix = suffix

        copy isThisRef = isThisRef
        copy context = context
        copy owner = owner
        copy verzion = verzion

        copy fromClosure = fromClosure

        args each(|e|
            copy args add(e clone())
        )
        copy returnType = returnType clone()

        body list each(|e|
            copy body add(e clone())
        )

        typeArgs each(|ta|
            copy typeArgs add(ta clone())
        )

        returnArgs each(|ra|
            copy returnArgs add(ra clone())
        )

        copy vDecl = vDecl

        copy
    }

    accept: func (visitor: Visitor) { visitor visitFunctionDecl(this) }

    addTypeArg: func (typeArg: VariableDecl) -> Bool { typeArgs add(typeArg); true }

    getReturnType: func -> Type { returnType }
    setReturnType: func(type: Type) { this returnType = type }

    setName: func (=name) {}
    getName: func -> String { name }

    getSuffixOrEmpty: func -> String {
        suffix ? suffix : ""
    }
    getSuffix: func -> String { suffix }
    setSuffix: func(suffix: String) { this suffix = suffix }

    isStatic:    func -> Bool { isStatic }
    setStatic:   func (=isStatic) {}

    isAbstract:  func -> Bool { isAbstract }
    setAbstract: func (=isAbstract) {}

    isFinal:     func -> Bool { isFinal }
    setFinal:    func (=isFinal) {}

    isInline:    func -> Bool { isInline }
    setInline:   func (=isInline) {}

    isProto:    func -> Bool { isProto }
    setProto:   func (=isProto) {}

    isSuper:    func -> Bool { isSuper }
    setSuper:   func (=isSuper) {}

    isAnon: func -> Bool { isAnon }

    debugCondition: final func -> Bool {
        false
    }

    markForPartialing: func(var: VariableDecl, mode: String) {
        if (!partialByReference contains?(var)) {
            match (mode) {
                case "r" =>
                    if(partialByValue contains?(var)) partialByValue remove(var)
                    partialByReference add(var)
                case "v" =>
                    if(partialByValue contains?(var)) return
                    partialByValue add(var)
            }
        }
    }

    setOwner: func (=owner) {}
    getOwner: func -> TypeDecl { owner }

    getStaticVariant: func -> This {
        if(isStatic) {
            token module params errorHandler onError(
            InternalError new(token, "Should get the static variant of a static function.. wtf?"))
        }

        if(!staticVariant) {
            staticVariant = new(name, token)
            staticVariant suffix = suffix
            staticVariant args = args clone()
            staticVariant returnType = returnType
            staticVariant args add(0, owner getThisDecl())
            staticVariant isStatic = true
            staticVariant owner = owner
        }
        staticVariant
    }

    getReturnArg: func -> VariableDecl {
        if(returnArgs empty?()) createReturnArg(returnType, "genericReturn")
        return returnArgs[0]
    }

    createReturnArg: func (type: Type, name: String) {
        returnArgs add(VariableDecl new(type, generateTempName(name), token))
    }

    getReturnArgs: func -> List<VariableDecl> {
        return returnArgs
    }

    hasReturn: func -> Bool {
        returnType != voidType && !returnType isGeneric()
    }

    hasThis:  func -> Bool { isMember() && !isStatic() }

    isMember: func -> Bool { owner != null }

    getExternName: func -> String { externName }
    setExternName: func (=externName) {}
    isExtern: func -> Bool { externName != null }
    isExternWithName: func -> Bool {
        (externName != null) && !(externName empty?())
    }

    getUnmangledName: func -> String { unmangledName empty?() ? name : unmangledName }
    setUnmangledName: func (=unmangledName) {}
    isUnmangled: func -> Bool { unmangledName != null }
    isUnmangledWithName: func -> Bool {
        (unmangledName != null) && !(unmangledName empty?())
    }

    getFullName: func -> String {
        if(fullName == null) {
            if(isUnmangled()) {
                fullName = getUnmangledName()
            } else if(isEntryPoint()) {
                fullName = name
            } else {
                if(isMember()) {
                    fullName = "%s_%s" format(owner getFullName(), name)
                } else {
                    fullName = "%s__%s" format(token module getUnderName(), name)
                }
                if(suffix != null) {
                    fullName = "%s_%s" format(fullName, suffix)
                }
            }
        }
        fullName
    }

    isEntryPoint: func -> Bool {
        !isMember() && token module params entryPoint == name
    }

    getType: func -> FuncType {
        type := FuncType new(token)
        if(owner && !isStatic && !vDecl) {
            type isClosure = true // Hack-ish way to prevent wrapping an access to a method into a closure structure
            type argTypes add(owner instanceType)
        }
        for(arg in args) {
            if(arg instanceOf?(VarArg)) break
            type argTypes add(arg getType())
        }
        type returnType = returnType
        for(typeArg in typeArgs) {
            type addTypeArg(typeArg)
        }
        if (vDecl != null) {
            type isClosure = true
        }

        return type
    }

    getArgsRepr: func -> String {
        getArgsRepr(null)
    }

    getArgsRepr: func ~withCallContext (call: FunctionCall) -> String {
        if(args getSize() == 0) return ""
        sb := Buffer new()
        if(typeArgs != null && !typeArgs empty?()) {
            sb append("<")
            isFirst := true
            for(typeArg in typeArgs) {
                if(isFirst) isFirst = false
                else        sb append(", ")
                sb append(typeArg getName())
            }
            sb append("> ")
        }
        sb append("(")
        isFirst := true
        for(arg in args) {
            if(isFirst) isFirst = false
            else        sb append(", ")
            sb append(arg toString()). append(" :")
            argType := arg getType()
            if(argType) {
                if(call) {
                    finalScore := 0
                    solved := call resolveTypeArg(argType getName(), null, finalScore&)
                    if(solved) argType = solved
                }
                sb append(argType toString())
            } else {
                sb append("...")
            }
        }
        sb append(")")
        return sb toString()
    }

    toString: func -> String {
        toString(null)
    }

    toString: func ~withCallContext (call: FunctionCall) -> String {
        (isStatic ? "static " : "") +
        (owner ? owner getName() + " " : "") +
        (suffix ? (prettyName + "~" + suffix) : prettyName) +
        getArgsRepr(call) +
        (hasReturn() ? " -> " + returnType toString() : "")
    }

    isResolved: func -> Bool { false }

    eachTypeArgMappingUntil: func (typeArgName: String, f: Func (Int, String) -> Bool) {
        i := -1
        for (arg in args) {
            i += 1
            if (arg getType() == null) continue

            if (debugCondition()) "Looking for typeArg %s in arg's type %s" printfln(typeArgName, arg getType() toString())

            type := arg getType()
            typeArgs := type getTypeArgs()

            if (typeArgs == null) continue
            j := -1
            for (typeArg in typeArgs) {
                j += 1
                if (debugCondition()) "%s vs %s" printfln(typeArg getName(), typeArgName)

                if (typeArg getName() == typeArgName) {
                    // found it! now get the real typeArgName and resolve that.
                    if (!type getRef() instanceOf?(TypeDecl)) {
                        if (debugCondition()) "Ref isn't a type, it's: %s" printfln(type getRef() toString())
                        continue
                    }
                    typeRef := type getRef() as TypeDecl

                    typeRefTypeArgs := typeRef getTypeArgs()
                    if (typeRefTypeArgs == null) {
                        if (debugCondition()) "Type args of %s is null" printfln(typeRef toString())
                        continue
                    }
                    realTypeArgName := typeRefTypeArgs get(j) getName()

                    if (!f(i, realTypeArgName)) {
                        return // all good!
                    }
                }
            }
        }
    }

    resolveType: func (type: BaseType, res: Resolver, trail: Trail) -> Int {

        for(typeArg: VariableDecl in typeArgs) {
            if(typeArg name == type name) {
                type suggest(typeArg)
                return 0
            }
        }

        0

    }

    resolveCall: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        for(arg: Argument in args) {
            if((arg getType() instanceOf?(FuncType) || (arg getType() != null && arg getType() getName() == "Closure")) &&
                    arg getName() == call getName()) {
                call suggest(arg getFunctionDecl(), res, trail)
                break
            }
        }
        0
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {

        if (context) {
            //printf("Looking for %s in %s, context = %s, access ref = %s\n", access toString(), toString(), context toString(), access ref ? access ref toString() : access ref)
            for(node in context backward()) {
                node resolveAccess(access, res, trail)
            }
        }

        if(owner != null && access name == "this") {
            meat := owner
            if(meat isAddon()) {
                // rule of resolve club: never resolve to the adddon, resolve to the
                // base instead
                meat = meat getBase() getNonMeta()
            }

            if(access suggest(isThisRef ? meat thisRefDecl : meat thisDecl)) {
                return 0
            }
        }

        if(access debugCondition()) {
            "Looking for %s in %s, got %d typeArgs" printfln(access toString(), toString(), typeArgs size)
        }

        for(typeArg in typeArgs) {
            if(access name == typeArg name) {
                if(access suggest(typeArg)) return 0
            }
        }

        for(arg in args) {
            if(access name == arg name) {
                if(access suggest(arg)) return 0
            }
        }

        // FIXME: I'm pretty sure this isn't necessary (harmful, even)
        body resolveAccess(access, res, trail)

        0

    }

    argumentsReady: func -> Bool {
        for (arg in args) {
            if (arg getType() == null) return false
        }
        return true
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(debugCondition() || res params veryVerbose) "** Resolving function decl %s" printfln(prettyName)

        if(debugCondition()) ("isFatal ? " + res fatal toString()) println()

        trail push(this)

        if (verzion && !verzion isResolved()) {
            verzion resolve(trail, res)
        }

        if(debugCondition()) "Handling the owner" println()

        // handle the case where we specialize a generic function
        if(owner) {
            meat := owner isMeta ? owner as ClassDecl : owner getMeta()
            comeBack: Bool
            base := meat getBaseClass(this, true, comeBack&)
            if (comeBack) { // ugly_
                res wholeAgain(this, "Resolving a missing interface declaration.")
                return Response OK
            }

            if(base != null) {
                finalScore := 0
                parent := base getFunction(name, suffix ? suffix : "", null, false, finalScore&)
                if(finalScore == -1) {
                    res wholeAgain(this, "Something's not resolved, need base getFunction()")
                    if(debugCondition()) "Got -1 from finalScore!" println()
                    return Response OK
                }
                // todo: check for finalScore
                for(i in 0..args getSize()) {
                    arg := args[i]
                    if(arg getType() instanceOf?(FuncType)) {
                        fType1 := arg getType() as FuncType
                        // TODO: add check 1) number of argument 2) it's a FuncType
                        fType2 := ((i < parent args getSize()) ? parent args[i] getType() : null) as FuncType

                        //"for %s, got %s vs %s" printfln(toString(), fType1 toString(), fType2 toString())

                        for(j in 0..fType1 argTypes getSize()) {
                            type1 := fType1 argTypes[j]
                            type2 := (fType2 != null && j < fType2 argTypes getSize()) ? fType2 argTypes[j] : null
                            if(type2 != null) {
                                if(!type1 isResolved() || !type2 isResolved()) {
                                    res wholeAgain(this, "should determine interface specialization")
                                    break
                                }
                                if(type2 isGeneric() && !type1 isGeneric()) {
                                    // there's a specialization going on!
                                    fType1 argTypes[j] = type2
                                    if(!genericConstraints) {
                                        genericConstraints = HashMap<Type, Type> new()
                                    }
                                    genericConstraints put(type2 clone(), type1 clone())
                                }
                            }
                        }
                    }
                }
            }
        }

        if(debugCondition()) "Handling the args" println()

        for(arg in args) {
            if(debugCondition()) "Handling arg %s" format(arg toString()) println()
            response := arg resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) "Response of arg %s = %s" printfln(arg toString(), response toString())
                trail pop(this)
                return response
            }
        }

        if(debugCondition()) "Handling isClosure" println()

        isClosure := name empty?()

        if (isClosure) {
            fromClosure = true

            //if (!_unwrappedACS && !argumentsReady()) {
            if (!_unwrappedACS) {
                if (!unwrapACS(trail, res)) {
                    trail pop(this)
                    return Response OK
                }
            }
            args each(| arg |
                if (arg getType() == null || !arg getType() isResolved()) {
                    "Looping because of arg %s" format(arg toString()) println()
                    res wholeAgain(this, "need arg type for the ref")
                    return
                }
            )
        }

        if(debugCondition()) "Handling typeArgs" println()

        for(typeArg in typeArgs) {
            response := typeArg resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) "Response of typeArg %s = %s" printfln(typeArg toString(), response toString())
                trail pop(this)
                return response
            }
        }

        if(debugCondition()) "Handling the body." println()

        {
            response := returnType resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) "))))))) For %s, response of return type %s = %s" printfln(toString(), returnType toString(), response toString())
                trail pop(this)
                return response
            }
            if(!returnType isResolved()) {
                res wholeAgain(this, "need returnType of a FunctionDecl to be resolved")
                trail pop(this)
                return Response OK
            } else if(returnType isGeneric()) {
                if(returnArgs empty?()) createReturnArg(returnType, "genericReturn")
            } else if(returnType instanceOf?(TypeList)) {
                list := returnType as TypeList
                if(returnArgs empty?()) {
                    for(type in list types) {
                        createReturnArg(ReferenceType new(type, type token), "tupleArg")
                    }
                }
            }
        }

        {
            response := body resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) "))))))) For %s, response of body = %s" printfln(toString(), response toString())
                trail pop(this)
                res wholeAgain(this, "body wanna LOOP")
                return Response OK

                // Why aren't we relaying the response of the body? Because
                // the trail is usually clean below the body and it would
                // blow-up way too soon if we LOOP-ed on every foreach/evil thing
                //return response
            }
        }

        if(!isAbstract() && !isExtern() && vDecl == null) {
            if(isMain()) {
                if(isVoid()) {
                    returnType = BaseType new("Int", token)
                    body add(Return new(IntLiteral new(0, nullToken), nullToken))
                    res wholeAgain(this, "because changed returnType to %s" format(returnType toString()))
                }
            }

            response := autoReturn(trail, res, this, body, returnType)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) "))))))) For %s, response of autoReturn = %s" printfln(toString(), response toString())
                trail pop(this)
                return response
            }
        }
        trail pop(this)

        if(isSuper) {
            if(!owner) {
                res throwError(SyntaxError new(token, "Super funcs are only legal in type declarations!"))
            }

            superTypeDecl := owner getSuperRef()
            finalScore: Int
            ref := superTypeDecl getMeta() getFunction(name, suffix, null, finalScore&)
            if(finalScore == -1) {
                res wholeAgain(this, "something in our typedecl's functions needs resolving!")
                return Response OK
            }

            superCall := FunctionCall new("super", token)
            if(ref != null) {
                if(ref isSuper) {
                    // oh really? then wait until it's not super anymore.
                    res wholeAgain(this, "superRef of a super func is super itself! looping.")
                    return Response OK
                }

                for(arg in ref args) {
                    if(!arg isResolved()) {
                        res wholeAgain(arg, "some arg we need to copy needs resolving!")
                        return Response OK
                    }
                }

                args addAll(ref args)

                for(arg in ref args) {
                    superCall args add(VariableAccess new(arg, arg token))
                }
                body add(superCall)

                isSuper = false

                if(name == "init") {
                    // add ourselves again, for new-generation from init
                    owner removeFunction(this)
                    owner addFunction(this)
                }

                res wholeAgain(this, "Just changed super func")
            } else {
                msg := "There is no such super-func in %s!" format(superTypeDecl toString())
                err := UnresolvedCall new(token, superCall, msg)
                res throwError(err)
            }
        }

       if(name == "main" && owner == null) {
            // TODO: move me out of middle/ !!

            match (args getSize()) {
                case 0 => {
                    // turn main into a standard prototype. Some libraries, like SDL, will
                    // require that because of SDL_main.
                    argc := Argument new(BaseType new("Int", token), generateTempName("argc"), token)
                    argv := Argument new(PointerType new(BaseType new("CString", token), token), generateTempName("argv"), token)
                    args add(argc)
                    args add(argv)
                }
                case 1 => {
                    // replace (args: ArrayList<String>) with (argc: Int, argv1: CString*)
                    // and assign args to the array-list version of main's arguments
                    if (args first() getType() getName() == "ArrayList") {
                        arg := args first()
                        args clear()
                        argc := Argument new(BaseType new("Int", arg token), generateTempName("argc"), arg token)
                        argv := Argument new(PointerType new(BaseType new("CString", arg token), arg token), generateTempName("argv"), arg token)
                        args add(argc)
                        args add(argv)

                        constructCall := FunctionCall new("strArrayListFromCString", arg token)
                        constructCall args add(VariableAccess new(argc, arg token)) \
                                          .add(VariableAccess new(argv, arg token))
                        // Mangle the argument's name :D
                        arg fullName = "%s__%s" format(arg token module getUnderName(), arg name)
                        vdfe := VariableDecl new(null, arg getFullName(), constructCall, token)
                        body add(0, vdfe)
                    }else if(args first() getType() getName() == "String"){
                        // replace (String[]) with (argc: Int, argv: CString*)
                        // and assign args to string array
                        arg := args first()
                        args clear()
                        argc := Argument new(BaseType new("Int", arg token), generateTempName("argc"), arg token)
                        argv := Argument new(PointerType new(BaseType new("CString", arg token), arg token), generateTempName("argv"), arg token)
                        args add(argc)
                        args add(argv)

                        constructCall := FunctionCall new("strArrayFromCString", arg token)
                        constructCall args add(VariableAccess new(argc, arg token)) \
                                          .add(VariableAccess new(argv, arg token))
                        arg fullName = "%s__%s" format(arg token module getUnderName(), arg name)
                        vdfe := VariableDecl new(null, arg getFullName(), constructCall, token)
                        body add(0, vdfe)
                    }
                }
                case 2 => {
                    // Replace (argc: Int, argv: String*) with (argc: Int, argv1: CString*)
                    // and assign argv to the "String" version of argv1
                    // argv := cStringPtrToStringPtr(argv1, argc)

                    if (args get(0) getType() getName() == "Int" && args get(1) getType() getName() == "String") {
                        arg := args get(1)
                        pseudoArgv := BaseType new("CString", arg token)
                        argv := Argument new(PointerType new(pseudoArgv, arg token), generateTempName("argv"), arg token)
                        argvAccess := VariableAccess new(argv, argv token)
                        argcAccess := VariableAccess new(args get(0), args get(0) token)
                        constructCall := FunctionCall new("cStringPtrToStringPtr", arg token)
                        constructCall args add(argvAccess)
                        constructCall args add(argcAccess)

                        myArgv := VariableDecl new(null, "argv", constructCall, nullToken)
                        args[1] = argv
                        body add(0, myArgv)
                    }
                }
            }
        }

        if (isClosure) {
            if(countdown > 0) {
                countdown -= 1
                res wholeAgain(this, "countdown!")
            } else {
                unwrapClosure(trail, res)
            }
        }

        return Response OK
    }

    unwrapACS: func (trail: Trail, res: Resolver) -> Bool {
        if(_unwrappedACS) return true

        fCallIndex := trail find(FunctionCall)
        if (fCallIndex == -1) {
            if(argumentsReady()) {
                _unwrappedACS = true
                return true
            } else {
                res throwError(InternalError new(token, "Got an ACS without any function-call. THIS IS NOT SUPPOSED TO HAPPEN\ntrail= %s" format(trail toString())))
            }
        }
        parentCall := trail get(fCallIndex) as FunctionCall
        parentFunc := parentCall getRef()

        if (!parentFunc || parentCall refScore < 0) {
            res wholeAgain(this, "Need ACS reference.")
            return false
        }

        if (parentFunc getOwner()) {
            if(parentCall expr == null || parentCall expr getType() == null) {
                res wholeAgain(this, "Need type of the expr of the parent call")
                return false
            }

            j := 0
            callExprTypeArgs := parentCall expr getType() getTypeArgs()
            if(callExprTypeArgs) {
                for(typeArg in parentFunc getOwner() typeArgs) {
                    helperDecl := VariableDecl new(null, typeArg getName(), callExprTypeArgs get(j), token)
                    helperDecl externName = "" // declare it as extern so it doesn't get written
                    body add(0, helperDecl)
                    j += 1
                }
            }
        }

        ind := parentCall args indexOf(this)

        if (ind == -1) {
            res throwError(InternalError new(token, "[ACS]: Can't find `this` in the call's arguments.\ntrail = %s" format(trail toString())))
        }

        if(ind >= parentFunc args size) {
            res wholeAgain(this, "Invalid argument index - call candidate probably doesn't match")
            return false
        }

        argType := parentFunc args[ind] getType()
        if (!argType || argType class != FuncType) {
            res wholeAgain(this, "Missing type information in the function pointer.")
            return false
        }
        funcPointer := argType as FuncType

        ix := 0

        fScore := 0
        needTrampoline := false

        // infer return type
        if(funcPointer returnType) {
            returnType = funcPointer returnType
        }

        // infer arg types
        for (fType in funcPointer argTypes) {
            if (!fType isResolved()) {
                res wholeAgain(this, "Can't figure out the type of the argument.")
                return false
            }
            if (fType isGeneric()) needTrampoline = true
            args get(ix) type = fType
            ix += 1
        }

        if(funcPointer typeArgs) for(typeArg in funcPointer typeArgs) {
            addTypeArg(typeArg)
        }

        if (needTrampoline) {

            /*
                1. The generic function arguments get the postfix "_generic".
                2. The type of each generic argument is figured out.
                3. Right at the beginning of the function casts to the actual types
                   are added.
                Example:
                    test: func<T> (b: T) { b println() }
                becomes
                    test: func<T> (b_generic: T) { b := b_generic as String; b println() }
            */

            for (arg in args) {
                if (arg getType() isGeneric()) {
                    oldName := arg name
                    genType := parentCall resolveTypeArg(arg getType() getName(), trail, fScore&)
                    if (fScore == -1 || genType == null) {
                        res wholeAgain(this, "Can't figure out the actual type of the generic.")
                        return false
                    }
                    if(genType isGeneric()) {
                        continue
                    }
                    arg name = arg name + "_generic"
                    genType = genType clone()
                    genType token = arg token
                    castedArg := VariableDecl new(genType, oldName, Cast new(VariableAccess new(arg name, arg token), genType, arg token), arg token)
                    body list add(0, castedArg)
                }

            }
        }
        _unwrappedACS = true
        return true
    }

    unwrapClosure: func (trail: Trail, res: Resolver) {
        if(_unwrappedClosure) return

        for(e in partialByReference) {
            if(e getType() == null || !e getType() isResolved()) {
                res wholeAgain(this, "Need partial-by-reference's return types")
                return
            }
        }

        for (e in partialByValue) {
            if(e getType() == null || !getType() isResolved()) {
                res wholeAgain(this, "Need partial-by-value's return types")
                return
            }
        }

        // find the outer function call
        parentIdx := trail find(FunctionCall)
        parentCall := (parentIdx != -1 ? trail get(parentIdx, FunctionCall) : null)

        if(parentCall && parentCall getRef() == null) {
            res wholeAgain(this, "Need outer call ref")
            return
        }

        module := trail module()

        name = generateTempName(module getUnderName() + "_closure")
        isGenerated = true
        varAcc := VariableAccess new(name, token)
        varAcc setRef(this)
        module addFunction(this)

        closureType := getType() clone()
        closureType as FuncType isClosure = true

        isFlat := (parentCall != null && parentCall getRef() isExtern())
        if (isFlat) {
            message := "Passing closure to C function - that's no good!"
            res throwError(InternalError new(token, message))
            return
        }

        if(partialByReference empty?() && partialByValue empty?()) {

            closureElements := [
                varAcc
                NullLiteral new(token)
            ] as ArrayList<Expression>

            closure := StructLiteral new(closureType, closureElements, token)
            trail peek() replace(this, closure)

        } else {

            // create the context struct's cover
            ctxStruct := CoverDecl new(name + "_ctx", token)
            ctxStruct isGenerated = true
            ctxStruct fromClosure = true

            // look for versioned nodes or VersionBlocks in the trail. If we're using
            // a closure in a versioned context, we don't want the context struct to appear
            // in any other context - it results in gcc errors. See #197.
            // The same `ctxVersion` instance is used for the thunk function later.
            ctxVersion: VersionSpec
            for(i in 1..trail size) {
                node := trail peek(i)
                verzion: VersionSpec
                // There are several types of versioned nodes.
                if(node instanceOf?(TypeDecl) && node as TypeDecl verzion != null) {
                    // TypeDecl?
                    verzion = node as TypeDecl verzion
                } else if(node instanceOf?(FunctionDecl) && node as FunctionDecl verzion != null) {
                    // Or a versioned FunctionDecl?
                    verzion = node as FunctionDecl verzion
                } else if(node instanceOf?(VersionBlock)) {
                    // Or, of course, a version block.
                    verzion = node as VersionBlock spec
                } else {
                    // No? Okay. Skip this.
                    continue
                }
                // There is a version somewhere - merge the specs.
                if(ctxVersion == null) {
                    ctxVersion = verzion clone()
                } else {
                    ctxVersion = VersionAnd new(
                        ctxVersion,
                        verzion clone(),
                        node token
                    )
                }
            }

            if(ctxVersion != null)
                ctxStruct setVersion(ctxVersion)

            // add corresponding variables to the context struct
            // and to the struct initializer for the context
            elements := ArrayList<Expression> new()

            // by-value (read-only) variables
            for(e in partialByValue) {
                eDeclType := e getType() clone()
                eDecl := VariableDecl new(eDeclType, e getName(), token)
                ctxStruct addVariable(eDecl)
                elements add(VariableAccess new(e, e token))
            }

            // by-reference (read/write) variables
            for(e in partialByReference) {
                eDeclType := PointerType new(e getType(), e getType() token)
                eDecl := VariableDecl new(eDeclType, e getName(), token)
                ctxStruct addVariable(eDecl)
                elements add(AddressOf new(VariableAccess new(e, e token), token))
            }

            // add the context struct's cover to the Module so we can actually use it
            module addType(ctxStruct)

            // initialize the context struct
            ctxAllocCall := FunctionCall new("gc_malloc", token)
            ctxAllocCall args add(VariableAccess new(VariableAccess new(ctxStruct getInstanceType(), token), "size", token))
            ctxInit := StructLiteral new(ctxStruct getInstanceType(), elements, token)

            ctxDecl := VariableDecl new(PointerType new(ctxStruct getInstanceType(), token), generateTempName("ctx"), ctxAllocCall, token)
            trail addBeforeInScope(this, ctxDecl)

            ctxAssign := BinaryOp new(Dereference new(VariableAccess new(ctxDecl, token), token), ctxInit, OpType ass, token)
            trail addBeforeInScope(this, ctxAssign)

            closureElements := [
                VariableAccess new(getName() + "_thunk" /* hackish - would prefer a direct reference */, token)
                VariableAccess new(ctxDecl, token)
            ] as ArrayList<VariableAccess>

            closure := StructLiteral new(closureType, closureElements, token)
            closureDecl := VariableDecl new(null, generateTempName("closure"), closure, token)
            trail addBeforeInScope(this, closureDecl)

            thunk := FunctionDecl new(getName() + "_thunk", token)
            thunk isGenerated = true
            thunk fromClosure = true
            thunk typeArgs addAll(typeArgs)
            thunk args addAll(args)
            thunk returnType = returnType

            // The thunk might have to be versioned, too.
            if(ctxVersion != null)
                thunk setVersion(ctxVersion)

            ctxArg := VariableDecl new(ReferenceType new(ctxStruct getInstanceType(), token), "__context__", token)
            thunk args add(ctxArg)

            call := FunctionCall new(getName(), token)

            argOffset := 0

            // add to the thunk call the by-value variables from the context
            for(arg in partialByValue) {
                call args add(VariableAccess new(VariableAccess new(ctxArg, token), arg getName(), token))
            }

            // add to the thunk call the by-reference variables from the context
            for(arg in partialByReference) {
                call args add(VariableAccess new(VariableAccess new(ctxArg, token), arg getName(), token))
            }

            // add to the thunk call the variable arguments that are not part of the context
            for(arg in args) {
                call args add(VariableAccess new(arg, token))
            }
            thunk getBody() add(call)
            module addFunction(thunk)

            // now add the by-value variables from the context as arguments to the closure
            for(e in partialByValue) {
                argument := VariableDecl new(e getType(), e getName(), e token)
                args add(argOffset, argument); argOffset += 1
            }

            // now add the by-reference variables from the context as arguments to the closure
            for(e in partialByReference) {
                argumentType := ReferenceType new(e getType(), e getType() token)
                argument := VariableDecl new(argumentType, e getName(), e token)
                args add(argOffset, argument); argOffset += 1
                for (acs in clsAccesses) {
                    if (acs ref == e) acs ref = argument
                }
            }

            // now say that the FuncType arguments of our context are closures
            for(e in ctxStruct getVariables()) {
                if(e getType() instanceOf?(FuncType)) {
                    eType := e getType() clone()
                    eType as FuncType isClosure = true
                    e setType(eType)
                }
            }

            closureAcc := VariableAccess new(closureDecl, token)
            if(!trail peek() replace(this, closureAcc)) {
                res throwError(CouldntReplace new(token, this, closureAcc, trail))
            }

            _unwrappedClosure = true
            context = trail clone()
            res wholeAgain(this, "Unwrapped closure")
        }

    }

    /**
     * @return the score of decl, respective to this function decl.
     * This is used to check if function declarations are compatible,
     * for example to check if an interface function implementation
     * is compatible with the function signature in the interface decl
     */
    getScore: func (decl: FunctionDecl) -> Int {
        if(debugCondition()) {
            "** Getting score of #{this} vs #{decl}" println()
        }

        score := Type SCORE_SEED / 4

        // First things first: MUST share name
        if(name != decl name) {
            return Type NOLUCK_SCORE
        }

        // The two declarations MUST have the same signature
        if(suffix != decl suffix) {
            return Type NOLUCK_SCORE
        }

        // Check argument count
        // We don't have to worry about varargs etc., since both are declarations
        if(args getSize() != decl args getSize()) {
            return Type NOLUCK_SCORE
        }

        // Check ownership
        if(owner != null && decl owner != null) {
            // TODO: Check shit between owners
            score += Type SCORE_SEED / 4
        }

        // Check functions are both static
        if(isStatic == decl isStatic) {
            score += Type SCORE_SEED / 8
        }

        // Arguments
        declIter : Iterator<Argument> = decl args iterator()
        ourIter : Iterator<Argument> = args iterator()

        while(ourIter hasNext?() && declIter hasNext?()) {
            declArg := declIter next()
            ourArg := ourIter next()

            if(declArg getType() == null) {
                if(debugCondition()) "Score is -1 because of declArg %s\n" format(declArg toString()) println()
                return -1
            }
            if(ourArg getType() == null) {
                if(debugCondition()) "Score is -1 because of ourArg %s\n" format(ourArg toString()) println()
                return -1
            }

            declArgType := declArg getType() refToPointer()
            typeScore := ourArg getType() getScore(declArgType)
            if(typeScore == -1) {
                if(debugCondition()) {
                    "-1 because of type score between %s and %s" printfln(ourArg getType() toString(), declArgType refToPointer() toString())
                }
                return -1
            }

            score += typeScore

            if(debugCondition()) {
                "typeScore for %s vs %s == %d    for decl %s (%s vs %s) [%p vs %p]" printfln(
                    ourArg getType() toString(), declArgType refToPointer() toString(), typeScore, toString(),
                    ourArg getType() getGroundType() toString(), declArgType refToPointer() getGroundType() toString(),
                    ourArg getType() getRef(), declArgType getRef())
            }
        }

        // Return type
        typeScore := returnType getScore(decl returnType)

        if(typeScore == -1) {
            if(debugCondition()) {
                "-1 because of type score between return types #{returnType} and #{decl returnType}" println()
            }
            return -1
        }

        score += returnType getScore(decl returnType)

        if(debugCondition()) {
            "Final score = %d" printfln(score)
        }

        return score
    }

    isVoid: func -> Bool { returnType == voidType }

    isMain: func -> Bool { name == "main" && suffix == null && !isMember() }

    replace: func (oldie, kiddo: Node) -> Bool {
        if(oldie == returnType) {
            returnType = kiddo
            return true
        }

        body replace(oldie, kiddo)
    }

    addBefore: func (mark, newcomer: Node) -> Bool {
        body addBefore(mark, newcomer)
    }

    addAfter: func (mark, newcomer: Node) -> Bool {
        body addAfter(mark, newcomer)
    }

    isScope: func -> Bool { true }

    getTypeArgs: func -> ArrayList<VariableDecl> { typeArgs }
    getArguments: func -> ArrayList<Argument> { args }
    getBody: func -> Scope { body }

    setVersion: func (=verzion) {}
    getVersion: func -> VersionSpec { verzion }

}

FunctionRedefinition: class extends Error {

    first, second: FunctionDecl

    init: func (=first, =second) {
        super(second token, "Redefinition of '%s'%s" format(first prettyName, first verzion ? (" in version " + first verzion toString()) : ""))
        next = InfoError new(first token, "...first definition was here.")
    }

}
