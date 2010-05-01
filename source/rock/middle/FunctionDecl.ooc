import structs/[Stack, ArrayList], text/Buffer
import ../frontend/[Token, BuildParams]
import Expression, Type, Visitor, Argument, TypeDecl, Scope,
       VariableAccess, ControlStatement, Return, IntLiteral, If, Else,
       VariableDecl, Node, Statement, Module, FunctionCall, Declaration,
       Version, StringLiteral, Conditional, Import, ClassDecl, StringLiteral,
       IntLiteral, NullLiteral, BaseType, FuncType
import tinker/[Resolver, Response, Trail]

FunctionDecl: class extends Declaration {

    name = "", suffix = null, fullName = null : String
    returnType := voidType
    type : static Type = FuncType new(nullToken)
    
    /** Attributes */
    isAbstract := false
    isStatic := false
    isInline := false
    isFinal := false
    isProto := false
    externName : String = null
    unmangledName: String = null
    
    // if true, 'this' has byref semantics
    isThisRef := false
    
    /** If this FunctionDecl is a shim to make a VariableDecl callable, then vDecl is set to that variable decl. */
    vDecl : VariableDecl = null
    
    typeArgs := ArrayList<VariableDecl> new()
    args := ArrayList<Argument> new()
    returnArg : Argument = null
    body := Scope new()
    
    variablesToPartial := ArrayList<VariableDecl> new()

    owner : TypeDecl = null
    staticVariant : This = null
    
    verzion: VersionSpec = null
    isAnon: Bool

    init: func ~funcDecl (=name, .token) {
        super(token)
        this isAnon = name isEmpty()
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
    
    isAnon: func -> Bool { isAnon }
    
    debugCondition: func -> Bool {
        false
    }
    
    markForPartialing: func(var: VariableDecl) {
        if (!variablesToPartial contains(var)) variablesToPartial add(var)
    }
    
    setOwner: func (=owner) {
        if(isStatic) return
        staticVariant = new(name, token)
        staticVariant suffix = suffix
        staticVariant args = args clone()
        staticVariant returnType = returnType
        staticVariant args add(0, owner getThisDecl())
        staticVariant isStatic = true
        staticVariant owner = owner
    }
    getOwner: func -> TypeDecl { owner }
    
    getStaticVariant: func -> This { staticVariant }
    
    getReturnArg: func -> Argument {
        if(returnArg == null) {
            returnArg = Argument new(getReturnType(), generateTempName("returnArg"), token)
        }
        return returnArg
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
        (externName != null) && !(externName isEmpty())
    }

    getUnmangledName: func -> String { unmangledName isEmpty() ? name : unmangledName }
    setUnmangledName: func (=unmangledName) {}
    isUnmangled: func -> Bool { unmangledName != null }
    isUnmangledWithName: func -> Bool {
        (unmangledName != null) && !(unmangledName isEmpty())
    }

    getFullName: func -> String {
        if(fullName == null) {
            if(isUnmangled()) {
                fullName = getUnmangledName()
            } else if(isEntryPoint()) {
                fullName = name
            } else if(isExtern()) {
                if(isExternWithName()) {
                    fullName = externName
                } else {
                    fullName = name
                }
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
    
    getType: func -> Type { This type }

    getArgsRepr: func -> String {
        if(args size() == 0) return ""
        sb := Buffer new()
        if(typeArgs != null && !typeArgs isEmpty()) {
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
            sb append(arg toString())
        }
        sb append(")")
        return sb toString()
    }
    
    toString: func -> String {
        (owner ? owner getName() + "." : "") + (suffix ? (name + "~" + suffix) : name) + (isStatic ? ": static func " : ": func ") + getArgsRepr() + (hasReturn() ? " -> " + returnType toString() : "")
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
            if(arg getName() == call getName() && arg getType() instanceOf(FuncType)) {
                call suggest(arg getFunctionDecl())
                break
            }
        }
        0
    }
    
    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        
        //printf("Looking for %s in %s\n", access toString(), toString())
        
        if(owner != null && access name == "this") {
            if(access suggest(isThisRef ? owner thisRefDecl : owner thisDecl)) return
        }
        
        for(typeArg in typeArgs) {
            if(access name == typeArg name) {
                if(access suggest(typeArg)) return
            }
        }
        
        for(arg in args) {
            if(access name == arg name) {
                if(access suggest(arg)) return
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
        
        trail push(this)
        
        if(debugCondition() || res params veryVerbose) printf("** Resolving function decl %s\n", name)

        for(arg in args) {
            response := arg resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("Response of arg %s = %s\n", arg toString(), response toString())
                trail pop(this)
                return response
            }
        }
        if (name isEmpty() && !argumentsReady()) { // Is this an ACS?
            n := trail find(FunctionCall)
            fCall_ := trail get(trail find(FunctionCall)) as FunctionCall
            fRef_ := fCall_ getRef()
            if (!fRef_) {
                res wholeAgain(this, "Need ACS ref.")
                trail pop(this)
                return Responses OK
            }
            funcPointer: FuncType = null
            for (arg in fRef_ args) {
                if (arg getType() instanceOf(FuncType)) {
                    funcPointer = arg
                    break
                }
            }
            if (!funcPointer) {
                res wholeAgain(this, "Missing type-info in func-pointer")
                trail pop(this)
                return Responses OK
            } 
            ix := 0
            tmp := funcPointer argTypes
            if (funcPointer argTypes instanceOf(ArrayList<Type>)) "yay" println()
            printf("%d\n", tmp size)
            printf("argTypes size: %d\n", funcPointer argTypes size())
            printf("argTypes: %p\n", funcPointer argTypes)
                        
            for (fType in funcPointer argTypes) {
                args get(ix) type = fType
                ix += 1
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
            if(returnType getRef() == null) {
                res wholeAgain(this, "need returnType of decl " + name)
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
				constructCall typeArgs add(VariableAccess new(BaseType new("Pointer", arg token), arg token))
				constructCall args add(VariableAccess new(argv, arg token)) \
                                  .add(VariableAccess new(argc, arg token))

                vdfe := VariableDecl new(null, arg getName(), constructCall, token)
				body add(0, vdfe)
			}
		}
        
        if (name isEmpty()) {
            unwrapClosure(trail, res)
        }
        
        if(verzion) {
            response := verzion resolve()
            if(!response ok()) return response
        }
        
        return Responses OK
        
    }
    
    unwrapClosure: func (trail: Trail, res: Resolver) {
        
        for(e in variablesToPartial) {
            if(e getType() == null || !e getType() isResolved()) {
                res wholeAgain(this, "Need variables-to-partieled's return types")
                return
            }
        }
        
        module := trail module()
        name = generateTempName(module getUnderName() + "_closure")
        varAcc := VariableAccess new(name, token)
        varAcc setRef(this)
        module addFunction(this)
     
        imp := Import new("internals/yajit/Partial", token) 
        module addImport(imp)
        module parseImports(res)
        
        if(variablesToPartial isEmpty()) {
            trail peek() replace(this, varAcc)
        } else {
            partialClass := VariableAccess new("Partial", token)
            newCall := FunctionCall new(partialClass, "new", token)
            partialName := generateTempName("partial")
            partialDecl := VariableDecl new(null, partialName, newCall, token)
            trail addBeforeInScope(this, partialDecl) 

            argsSizes := String new(args size())
            for(i in 0..args size()) {
                arg := args[i]
                typeName := arg getType() getName() toLower()
                val : Char = match (typeName) {
                    case "char"   => 'c'
                    case "double" => 's'
                    case "float"  => 'f'
                    case "short"  => 'h'
                    case "int"    => 'i'
                    case "long"   => 'l'
                    case          =>
                        if(!arg getType() isPointer() && !arg getType() getGroundType() isPointer() && !arg getType() getRef() instanceOf(ClassDecl)) {
                            arg token throwError("Unknown closure arg type %s\n" format(arg getType() toString()))
                        }
                        'P'
                }
                argsSizes[i] = val
            }
            
            partialAcc := VariableAccess new(partialName, token)
            for (e in variablesToPartial) {
                addArg := FunctionCall new(partialAcc, "addArgument", token)
                addArg getArguments() add(VariableAccess new(e, e token))
                trail addBeforeInScope(this, addArg)
                args add(Argument new(e getType(), e getName(), token))
            }
            
            fCall := FunctionCall new(partialAcc, "genCode", token)
            fCall getArguments() add(VariableAccess new(name, token)) 
            fCall getArguments() add(StringLiteral new(argsSizes, token))
            trail peek() replace(this, fCall)
            
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
        
        if(scope isEmpty()) {
            //printf("[autoReturn] scope is empty, we need a return\n")
            returnNeeded(trail)
            return
        }

        handleLastStatement(trail, res, scope, scope lastIndex())
        
    }
    
    handleLastStatement: func (trail: Trail, res: Resolver, scope: Scope, index: Int) {
        
        stmt := scope get(index)
        
        if(stmt instanceOf(Return)) {
            //printf("[autoReturn] Oh, it's a %s already. Nice =D!\n",  last toString())
            return
        }
        
        if(stmt instanceOf(Expression)) {
            expr := stmt as Expression
            if(expr getType() == null) {
                //printf("[autoReturn] LOOPing because stmt's type (%s) is null.", expr toString())
                res wholeAgain(this, "need the type of %s in autoReturn" format(stmt toString()))
                return
            }
            
            if(isMain() && !(expr getType() getName() == "Int" && expr getType() pointerLevel() == 0)) {
                returnNeeded(trail)
                res wholeAgain(this, "was needing return")
                return
            }
            
            if(!expr getType() equals(voidType)) {
                //printf("[autoReturn] Hmm it's a %s\n", stmt toString())
                scope set(index, Return new(expr, expr token))
                //printf("[autoReturn] Replaced with a %s!\n", scope get(index) toString())
            }
        } else if(stmt instanceOf(ControlStatement)) {
            cStat := stmt as ControlStatement
            if(cStat isDeadEnd()) {
                autoReturnExplore(trail, res, cStat getBody())
                if(cStat instanceOf(Else) && index > 0 && scope get(index - 1) instanceOf(Conditional)) {
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
            token throwError("Control reaches the end of non-void function! trail = " + trail toString())
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

