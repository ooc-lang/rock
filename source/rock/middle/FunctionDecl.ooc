import structs/[Stack, ArrayList], text/StringBuffer
import ../frontend/[Token, BuildParams]
import Expression, Type, Visitor, Argument, TypeDecl, Scope,
       VariableAccess, ControlStatement, Return, IntLiteral, Else,
       VariableDecl, Node, Statement, Module, FunctionCall, Declaration
import tinker/[Resolver, Response, Trail]

FunctionDecl: class extends Declaration {

    name = "", suffix = null : String
    returnType := voidType
    type: static Type = BaseType new("Func", nullToken)
    
    /** Attributes */
    isAbstract := false
    isStatic := false
    isInline := false
    isFinal := false
    externName : String = null
    
    typeArgs := ArrayList<VariableDecl> new()
    args := ArrayList<Argument> new()
    returnArg : Argument = null
    body := Scope new()
    
    owner : TypeDecl = null
    staticVariant : This = null

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
    
    getType: func -> Type { type }

    getArgsRepr: func -> String {
        if(args size() == 0) return ""
        sb := StringBuffer new()
        sb append("(")
        isFirst := true
        for(arg in args) {
            if(!isFirst) sb append(", ")
            sb append(arg toString())
            if(isFirst) isFirst = false
        }
        sb append(")")
        return sb toString()
    }
    
    toString: func -> String {
        (suffix ? (name + "~" + suffix) : name) + (isStatic ? ": static func " : ": func ") + getArgsRepr() + (hasReturn() ? " -> " + returnType toString() : "")
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
            if(access suggest(owner thisDecl)) return
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
        
        trail push(this)
        
        //printf("*/* Resolving function decl %s\n", name)

        for(arg in args) {
            response := arg resolve(trail, res)
            if(!response ok()) {
                if(res params verbose) printf("Response of arg %s = %s\n", arg toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        for(typeArg in typeArgs) {
            response := typeArg resolve(trail, res)
            if(!response ok()) {
                if(res params verbose) printf("Response of typeArg %s = %s\n", typeArg toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        {
            //printf("Resolving return type %s\n", returnType toString())
            response := returnType resolve(trail, res)
            if(!response ok()) {
                if(res params verbose) printf("))))))) For %s, response of return type %s = %s\n", toString(), returnType toString(), response toString()) 
                trail pop(this)
                return response
            }
        }
        
        {
            response := body resolve(trail, res)
            if(!response ok()) {
                if(res params verbose) printf("))))))) For %s, response of body = %s\n", toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        if(!isAbstract) {
            response := autoReturn(trail, res)
            if(!response ok()) {
                if(res params verbose) printf("))))))) For %s, response of autoReturn = %s\n", toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        trail pop(this)
        
        //printf("%s returning OK..\n", toString())
        
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
        
        stack := Stack<Iterator<Scope>> new()
        stack push(body iterator())
        
        //printf("[autoReturn] Exploring a %s\n", this toString())        
        if(!autoReturnExplore(stack, trail) ok()) {
            res wholeAgain(this, "autoReturnExplore said so!")
        }
        
        return finalResponse
        
    }
    
    autoReturnExplore: func (stack: Stack<Iterator<Statement>>, trail: Trail) -> Response {
        
        iter := stack peek()
        
        while(iter hasNext()) {
            node := iter next()
            if(node instanceOf(ControlStatement) && (node as ControlStatement isDeadEnd())) {
                cs := node as ControlStatement
                stack push(cs body iterator())
                //printf("[autoReturn] Sub-exploring a %s. isDeadEnd() ? %s\n", cs toString(), cs isDeadEnd() toString())
                autoReturnExplore(stack, trail)
            } else {
                //"[autoReturn] Huh, node is a %s, ignoring\n" format(node class name) println()
            }
        }
        
        stack pop()
        
        // if we're the bottom element, or if our parent doesn't have
        // any other element, we're at the end of control
        condition := stack isEmpty()
        if(!condition) {
            condition = !stack peek() hasNext()
        }
        if(!condition) {
            parentIter := stack peek()
            condition = true
            i := 0
            while(parentIter hasNext()) {
                i += 1
                next := parentIter next()
                if(!next instanceOf(ControlStatement)) {
                    //printf("[autoReturn] next is a %s, condition is then false :/\n", next class name)
                    condition = false
                    break
                }
            }
            while(i > 0) {
                parentIter prev()
                i -= 1
            }
        }
        
        if(condition) {
            list : Scope = iter as ArrayListIterator<Node> list
            if(list isEmpty()) {
                //printf("[autoReturn] scope is empty, needing return\n")
                returnNeeded(trail)
                return Responses LOOP
            }
            
            last := list last()
            
            if(last instanceOf(Return)) {
                //printf("[autoReturn] Oh, it's a %s already. Nice =D!\n",  last toString())
            } else if(last instanceOf(Expression)) {
                expr := last as Expression
                if(expr getType() == null) {
                    //printf("[autoReturn] LOOPing because last's type (%s) is null.", expr toString())
                    return Responses LOOP
                }
                
                if(isMain() && !expr getType() equals(IntLiteral type)) {
                    returnNeeded(trail)
                    return Responses LOOP
                }
                
                if(!expr getType() equals(voidType)) {
                    //printf("[autoReturn] Hmm it's a %s\n", last toString())
                    list set(list lastIndex(), Return new(last, last token))
                    //printf("[autoReturn] Replaced with a %s!\n", list last() toString())
                }
            } else if(last instanceOf(Else)) {
                // then it's alright, all cases are already handled
                //printf("[autoReturn] last is an Else, all cases are already handled\n", last toString())
            } else {
                //printf("[autoReturn] Huh, last is a %s, needing return\n", last toString())
                returnNeeded(trail)
                return Responses LOOP
            }
        }
        
        return Responses OK
        
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
    
}

