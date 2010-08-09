import structs/[Stack, ArrayList, List], text/Buffer
import ../frontend/[Token, BuildParams, AstBuilder]
import Cast, Expression, Type, Visitor, Argument, TypeDecl, Scope,
       VariableAccess, ControlStatement, Return, IntLiteral, If, Else,
       VariableDecl, Node, Statement, Module, FunctionCall, Declaration,
       Version, StringLiteral, Conditional, Import, ClassDecl, StringLiteral,
       IntLiteral, NullLiteral, BaseType, FuncType, AddressOf, BinaryOp,
       TypeList, CoverDecl, StructLiteral, Dereference
import tinker/[Resolver, Response, Trail, Errors]

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

     printf: extern func (fmt: Char*, ...)

   Or just regular Argument(s) :

     add: func (element: T) {}

*/
FunctionDecl: class extends Declaration {

    name = "", suffix = null, fullName = null, doc = "" : String

    returnType := voidType
    inferredReturnType : Type = null

    /** Attributes */
    isAbstract := false
    isStatic := false
    isInline := false
    isFinal := false
    isProto := false
    isSuper := false
    externName : String = null
    unmangledName: String = null
    // if true, 'this' has byref semantics
    isThisRef := false

    context: Trail = null
    countdown := 5

    /** If this FunctionDecl is a shim to make a VariableDecl callable, then vDecl is set to that variable decl. */
    vDecl : VariableDecl = null

    typeArgs := ArrayList<VariableDecl> new()
    args := ArrayList<VariableDecl> new()
    returnArgs := ArrayList<VariableDecl> new()
    body := Scope new()
    _returnTypeResolvedOnce := false

    partialByReference := ArrayList<VariableDecl> new()
    partialByValue := ArrayList<VariableDecl> new()
    clsAccesses := ArrayList<VariableAccess> new()
    _unwrappedClosure := false

    owner : TypeDecl = null
    staticVariant : This = null

    verzion: VersionSpec = null
    isAnon: Bool

    init: func ~funcDecl (=name, .token) {
        super(token)
        this isAnon = name empty?()
        this isFinal = (name == "init")
    }

    accept: func (visitor: Visitor) { visitor visitFunctionDecl(this) }

    addTypeArg: func (typeArg: VariableDecl) -> Bool { typeArgs add(typeArg); true }

    getReturnType: func -> Type { returnType }
    setReturnType: func(type: Type) { this returnType = type }

    setName: func (=name) {}
    getName: func -> String { name }

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

    debugCondition: inline func -> Bool {
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
        if(isStatic) token module params errorHandler onError(InternalError new(token, "Should get the static variant of a static function.. wtf?"))

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
        for(arg in args) {
            if(arg instanceOf?(VarArg)) break
            type argTypes add(arg getType())
        }
        type returnType = returnType
        for(typeArg in typeArgs) {
            type typeArgs add(VariableAccess new(typeArg, typeArg token))
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
        if(args size() == 0) return ""
        sb := Buffer new()
        if(typeArgs != null && !typeArgs empty?()) {
            sb append("<")
            isFirst := true
            for(typeArg in typeArgs) {
                if(isFirst) isFirst = false
                else        sb append(", ")
                if (typeArg == null) Exception new (This, "typeArg is NULL") throw()
                sb append(typeArg getName())
            }
            sb append("> ")
        }
        sb append("(")
        isFirst := true
        for(arg in args) {
            if(isFirst) isFirst = false
            else        sb append(", ")
            argType := arg getType()
            if(call) {
                finalScore := 0
                solved := call resolveTypeArg(argType getName(), null, finalScore&)
                if(solved) argType = solved
            }
            if(argType) {
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
        (owner ? owner getName() + " " : "") +
        (suffix ? (name + "~" + suffix) : name) +
        (isStatic ? " static" : "") +
        getArgsRepr(call) +
        (hasReturn() ? " -> " + returnType toString() : "")
    }

    isResolved: func -> Bool { false }

    resolveType: func (type: BaseType) {

        //printf("** Looking for type %s in func %s with %d type args\n", type name, toString(), typeArgs size())
        for(typeArg: VariableDecl in typeArgs) {
            //printf("*** For typeArg %s\n", typeArg name)
            if(typeArg name == type name) {
                //printf("***** Found match for %s in function decl %s\n", type name, toString())
                type suggest(typeArg)
                break
            }
        }

    }

    resolveCall: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        for(arg: Argument in args) {
            if((arg getType() instanceOf?(FuncType) || (arg getType() != null && arg getType() getName() == "Closure")) &&
                    arg getName() == call getName()) {
                call suggest(arg getFunctionDecl())
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
            if(meat isAddon()) meat = meat getBase() getNonMeta()
            if(access suggest(isThisRef ? meat thisRefDecl : meat thisDecl)) return 0
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

        if(debugCondition() || res params veryVerbose) printf("** Resolving function decl %s\n", name)

        trail push(this)

        for(arg in args) {
            response := arg resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("Response of arg %s = %s\n", arg toString(), response toString())
                trail pop(this)
                return response
            }
        }

        isClosure := name empty?()

        if (isClosure && !argumentsReady()) {
            if (!unwrapACS(trail, res)) {
                return Responses OK
            }
        }

        for(typeArg in typeArgs) {
            response := typeArg resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("Response of typeArg %s = %s\n", typeArg toString(), response toString())
                trail pop(this)
                return response
            }
        }

        {
            response := returnType resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("))))))) For %s, response of return type %s = %s\n", toString(), returnType toString(), response toString())
                trail pop(this)
                return response
            }
            if(!returnType isResolved()) {
                res wholeAgain(this, "need returnType of a FunctionDecl to be resolved")
            } else if(returnType isGeneric()) {
                // this create the returnArg for generic return types
                if(returnArgs empty?()) createReturnArg(returnType, "genericReturn")
            } else if(returnType instanceOf?(TypeList)) {
                list := returnType as TypeList
                if(list types size() > returnArgs size()) {
                    for(type in list types) {
                        createReturnArg(ReferenceType new(type, type token), "tupleArg")
                    }
                }
            }
        }

        {
            response := body resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("))))))) For %s, response of body = %s\n", toString(), response toString())
                trail pop(this)
                res wholeAgain(this, "body wanna LOOP")
                return Responses OK

                // Why aren't we relaying the response of the body? Because
                // the trail is usually clean below the body and it would
                // blow-up way too soon if we LOOP-ed on every foreach/evil thing
                //return response
            }
        }

        if(!isAbstract && vDecl == null) {
            response := autoReturn(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("))))))) For %s, response of autoReturn = %s\n", toString(), response toString())
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
                return Responses OK
            }
            superCall := FunctionCall new("super", token)
            if(ref != null) {
                for(arg in ref args) {
                    if(!arg isResolved()) {
                        res wholeAgain(arg, "some arg we need to copy needs resolving!")
                        return Responses OK
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
                    owner removeFunction(this). addFunction(this)
                }
            } else {
                res throwError(UnresolvedCall new(token, superCall, "There is no such super-func in %s!" format(superTypeDecl toString())))
            }
        }

        if(name == "main" && owner == null) {
            if(args size() == 1 && args first() getType() getName() == "ArrayList") {
                arg := args first()
                args clear()
                argc := Argument new(BaseType new("Int", arg token), "argc", arg token)
                argv := Argument new(PointerType new(BaseType new("String", arg token), arg token), "argv", arg token)
                args add(argc)
                args add(argv)

                constructCall := FunctionCall new(VariableAccess new(arg getType(), arg token), "new", arg token)
                constructCall setSuffix("withData")
                //constructCall typeArgs add(VariableAccess new(BaseType new("Pointer", arg token), arg token))
                constructCall args add(VariableAccess new(argv, arg token)) \
                                  .add(VariableAccess new(argc, arg token))

                vdfe := VariableDecl new(null, arg getName(), constructCall, token)
                body add(0, vdfe)
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

        return Responses OK
    }

    unwrapACS: func (trail: Trail, res: Resolver) -> Bool {

        fCallIndex := trail find(FunctionCall)
        if (fCallIndex == -1) {
            res throwError(InternalError new(token, "Got an ACS without any function-call. THIS IS NOT SUPPOSED TO HAPPEN\ntrail= %s" format(trail toString())))
        }
        parentCall := trail get(fCallIndex) as FunctionCall
        parentFunc := parentCall getRef()

        if (!parentFunc) {
            res wholeAgain(this, "Need ACS reference.")
            trail pop(this)
            return false
        }

        // FIXME FIXME FIXME: this will blow up with several closure arguments of different types!
        funcPointer: FuncType = null
        for (arg in parentFunc args) {
            if (arg getType() instanceOf?(FuncType)) {
                funcPointer = arg getType()
                break
            }
        }

        if (parentFunc getOwner()) {
            if(parentCall expr getType() == null) {
                res wholeAgain(this, "Need type of the expr of the parent call")
                trail pop(this)
                return false
            }

            j := 0
            callExprTypeArgs := parentCall expr getType() getTypeArgs()
            if(callExprTypeArgs) {
                for(typeArg in parentFunc getOwner() typeArgs) {
                    body add(0, VariableDecl new(null, typeArg getName(), callExprTypeArgs get(j), token))
                    j += 1
                }
            }
        }

        if (!funcPointer) {
            res wholeAgain(this, "Missing type informantion in the function pointer.")
            trail pop(this)
            return false
        }
        ix := 0

        fScore: Int
        needTrampoline := false
        for (fType in funcPointer argTypes) {
            if (!fType isResolved()) {
                res wholeAgain(this, "Can't figure out the type of the argument.")
                trail pop(this)
                return false
            }
            if (fType isGeneric()) needTrampoline = true
            args get(ix) type = fType
            ix += 1
        }
        if (funcPointer returnType) returnType = funcPointer returnType

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
                    n := arg name
                    t := parentCall resolveTypeArg(arg getType() getName(), trail, fScore&)
                    if (fScore == -1) {
                        res wholeAgain(this, "Can't figure out the actual type of the generic.")
                        trail pop(this)
                        return false
                    }
                    if(t isGeneric()) continue
                    arg name = arg name + "_generic"
                    t = t clone()
                    t token = arg token
                    castedArg := VariableDecl new(t, n, Cast new(VariableAccess new(arg name, arg token), t, arg token), arg token)
                    body list add(0, castedArg)
                }
            }
        }
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

        module := trail module()
        name = generateTempName(module getUnderName() + "_closure")

        varAcc := VariableAccess new(name, token)
        varAcc setRef(this)
        module addFunction(this)

        closureType := getType() clone()
        closureType as FuncType isClosure = true

        // find the outer function call
        parentIdx := trail find(FunctionCall)
        parentCall := (parentIdx != -1 ? trail get(parentIdx, FunctionCall) : null)
        isFlat := (parentCall != null && parentCall getRef() isExtern())

        if(partialByReference empty?() && partialByValue empty?()) {

            if(isFlat) {
                trail peek() replace(this, varAcc)
            } else {
                closureElements := [
                    varAcc
                    NullLiteral new(token)
                ] as ArrayList<Expression>

                closure := StructLiteral new(closureType, closureElements, token)
                trail peek() replace(this, closure)
            }

        } else {

            if(isFlat) {

                imp := Import new("internals/yajit/Partial", token)
                module addImport(imp)
                module parseImports(res)

                partialClass := VariableAccess new("Partial", token)
                newCall := FunctionCall new(partialClass, "new", token)
                partialName := generateTempName("partial")
                partialDecl := VariableDecl new(null, partialName, newCall, token)
                trail addBeforeInScope(this, partialDecl)
                parentCall: FunctionCall = null // ACS related, function call passing an ACS
                argsSizes := String new(args size())
                i := 0
                for(arg in args) {
                    t: Type
                    if (arg getType() isGeneric()) {
                        if (!parentCall) parentCall = trail get(trail find(FunctionCall)) as FunctionCall
                        fScore := 0
                        t = parentCall resolveTypeArg(arg getType() getName(), trail, fScore&)
                        if (fScore == -1) {
                            res wholeAgain(this, "Can't figure out the actual type of generic")
                            trail pop(this)
                            return Responses OK
                        }
                    } else {
                        t = arg getType()
                    }
                    t = t clone()
                    t token = arg token

                    typeName := t getName() toLower()
                    val : Char = match (typeName) {
                        case "char"   => 'c'
                        case "double" => 's'
                        case "float"  => 'f'
                        case "short"  => 'h'
                        case "int"    => 'i'
                        case "long"   => 'l'
                        case          =>

                            if(!arg getType() isPointer() && !arg getType() getGroundType() isPointer() && !arg getType() isGeneric() && !arg getType() getRef() instanceOf?(ClassDecl)) {
                                res throwError(InternalError new(arg token, "Unknown closure arg type %s\n" format(arg getType() toString())))
                            }
                            'P'
                    }
                    argsSizes[i] = val
                    i += 1
                }

                partialAcc := VariableAccess new(partialName, token)

                argOffset := 0

                for (e in partialByReference) {
                    newRefType := ReferenceType new(e getType(), e token)
                    eAccess := VariableAccess new(e, e token)

                    addArg := FunctionCall new(partialAcc, "addArgument", token)
                    addArg getArguments() add (AddressOf new (eAccess, e token))
                    trail addBeforeInScope(this, addArg)
                    argument := Argument new(newRefType, e getName(), token)
                    args add(argOffset, argument); argOffset += 1
                    for (acs in clsAccesses) {
                        if (acs ref == e) acs ref = argument
                    }
                }

                for (e in partialByValue) {
                    addArg := FunctionCall new(partialAcc, "addArgument", token)
                    addArg getArguments() add(VariableAccess new(e, e token))
                    trail addBeforeInScope(this, addArg)
                    argument := Argument new(e getType(), e getName(), e token)
                    args add(argOffset, argument); argOffset += 1
                }

                fCall := FunctionCall new(partialAcc, "genCode", token)
                fCall getArguments() add(VariableAccess new(name, token))
                fCall getArguments() add(StringLiteral new(argsSizes, token))
                trail peek() replace(this, fCall)

            } else {

                /* EXPERIMENTAL */

                // create the context struct's cover
                ctxStruct := CoverDecl new(name + "_ctx", token)

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
                thunk args addAll(args)
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

                /* EXPERIMENTAL - end */

            }

            _unwrappedClosure = true
            context = trail clone()
            res wholeAgain(this, "Unwrapped closure")
        }

    }

    autoReturn: func (trail: Trail, res: Resolver) -> Response {

        finalResponse := Responses OK

        if(isMain() && isVoid()) {
            returnType = BaseType new("Int", token)
            res wholeAgain(this, "because changed returnType to %s\n")
        }

        if(returnType == voidType || isExtern()) return Responses OK

        autoReturnExplore(trail, res, body)
        return Responses OK

    }

    autoReturnExplore: func (trail: Trail, res: Resolver, scope: Scope) {

        if(scope empty?()) {
            //printf("[autoReturn] scope is empty, we need a return\n")
            returnNeeded(trail)
            return
        }

        handleLastStatement(trail, res, scope, scope lastIndex())

    }

    handleLastStatement: func (trail: Trail, res: Resolver, scope: Scope, index: Int) {

        stmt := scope get(index)

        if(stmt instanceOf?(Return)) {
            //printf("[autoReturn] Oh, it's a %s already. Nice =D!\n",  last toString())
            return
        }

        if(stmt instanceOf?(Expression)) {
            expr := stmt as Expression
            if(expr getType() == null) {
                //printf("[autoReturn] LOOPing because stmt's type (%s) is null.", expr toString())
                res wholeAgain(this, "need the type of some statement in autoReturn")
                return
            }

            if(isMain() && !(expr getType() getName() == "Int" && expr getType() pointerLevel() == 0)) {
                returnNeeded(trail)
                res wholeAgain(this, "was needing return")
                return
            }

            if(!expr getType() equals?(voidType)) {
                //printf("[autoReturn] Hmm it's a %s\n", stmt toString())
                scope set(index, Return new(expr, expr token))
                res wholeAgain(this, "Replaced with a return o/")
                //printf("[autoReturn] Replaced with a %s!\n", scope get(index) toString())
            }
        } else if(stmt instanceOf?(ControlStatement)) {
            cStat := stmt as ControlStatement
            if(cStat isDeadEnd()) {
                autoReturnExplore(trail, res, cStat getBody())
                if(cStat instanceOf?(Else) && index > 0 && scope get(index - 1) instanceOf?(Conditional)) {
                    //printf("[autoReturn] Should handle the if too!\n")
                    handleLastStatement(trail, res, scope, index - 1)
                }
            } else {
                returnNeeded(trail)
            }
        } else {
            //printf("[autoReturn] Huh, last is a %s, needing return\n", last toString())
            returnNeeded(trail)
            res wholeAgain(this, "was needing return")
            return
        }

    }

    isVoid: func -> Bool { returnType == voidType }

    isMain: func -> Bool { name == "main" && suffix == null && !isMember() }

    returnNeeded: func (trail: Trail) {
        if(isMain()) {
            ret := Return new(IntLiteral new(0, nullToken), nullToken)
            body add(ret)
        } else {
            trail module() params errorHandler onError(InconsistentReturn new(token, "Control reaches the end of non-void function!"))
        }
    }

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
        message = second token formatMessage("Redefinition of '%s'%s" format(first getName(), first verzion ? " in version " + first verzion toString() : ""), "[INFO]") + '\n' +
                  first  token formatMessage("\n...first definition was here: ", "[ERROR]")
    }

    format: func -> String {
        message
    }

}

