import structs/[Stack, ArrayList], text/Buffer
import ../frontend/[Token, BuildParams]
import Expression, Type, Visitor, Argument, TypeDecl, Scope,
       VariableAccess, ControlStatement, Return, IntLiteral, If, Else,
       VariableDecl, Node, Statement, Module, FunctionCall, Declaration,
       Version, StringLiteral, Conditional
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
    
    owner : TypeDecl = null
    staticVariant : This = null
    
    verzion: VersionSpec = null

    init: func ~funcDecl (=name, .token) {
        super(token)
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
    
    isAnon:     func -> Bool {name isEmpty()}

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
            } else if(isMain()) { // FIXME: This should be isEntryPoint.
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
    
    resolveAccess: func (access: VariableAccess) {
        
        //printf("Looking for %s in %s\n", access toString(), toString())
        
        if(owner && access name == "this") {
            if(isThisRef) printf("Looking for %s in thisRef func %s\n", access toString(), toString())
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
        body resolveAccess(access)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if (isAnon()) {
            module := trail module()
            name = generateTempName(module getUnderName() + "_closure")
            varAcc := VariableAccess new(name, token)
            varAcc setRef(this)
            trail peek() replace(this, varAcc)
            module addFunction(this)
        }
        trail push(this)
        
        //if(res params veryVerbose) printf("** Resolving function decl %s\n", name)

        for(arg in args) {
            response := arg resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("Response of arg %s = %s\n", arg toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        for(typeArg in typeArgs) {
            response := typeArg resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("Response of typeArg %s = %s\n", typeArg toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        {
            response := returnType resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("))))))) For %s, response of return type %s = %s\n", toString(), returnType toString(), response toString()) 
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
                if(res params veryVerbose) printf("))))))) For %s, response of body = %s\n", toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        if(!isAbstract && vDecl == null) {
            response := autoReturn(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("))))))) For %s, response of autoReturn = %s\n", toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        trail pop(this)
        
        if(verzion) {
            response := verzion resolve()
            if(!response ok()) return response
        }
        
        return Responses OK
        
    }

    autoReturn: func (trail: Trail, res: Resolver) -> Response {
        
        finalResponse := Responses OK
        
        if(isMain() && isVoid()) {
            returnType = IntLiteral type
            //printf("Looping %s because of returnType, now %s\n", toString(), returnType toString())
            finalResponse = Responses LOOP
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
                res wholeAgain(this, "stmt's type is null")
                return
            }
            
            if(isMain() && !expr getType() equals(IntLiteral type)) {
                returnNeeded(trail)
                res wholeAgain(this, "was needing return")
                return
            }
            
            if(!expr getType() equals(voidType)) {
                //printf("[autoReturn] Hmm it's a %s\n", stmt toString())
                scope set(index, Return new(stmt, stmt token))
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
        match oldie {
            case returnType => returnType = kiddo; true
            case => body replace(oldie, kiddo) != null
        }
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

