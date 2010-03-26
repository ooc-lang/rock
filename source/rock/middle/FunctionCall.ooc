import structs/ArrayList, text/Buffer
import ../frontend/[Token, BuildParams]
import Visitor, Expression, FunctionDecl, Argument, Type, VariableAccess,
       TypeDecl, Node, VariableDecl, AddressOf, CommaSequence, BinaryOp,
       InterfaceDecl, Cast, NamespaceDecl
import tinker/[Response, Resolver, Trail]

FunctionCall: class extends Expression {

    expr: Expression
    name, suffix = null : String
    
    typeArgs := ArrayList<Expression> new()
    
    returnArg : Expression = null
    returnType : Type = null
    
    args := ArrayList<Expression> new()    
    
    ref = null : FunctionDecl
    refScore := -1
    
    init: func ~funcCall (=name, .token) {
        super(token)
    }

    init: func ~functionCallWithExpr (=expr, =name, .token) {
        super(token)
    }
    
    setExpr: func (=expr) {}
    getExpr: func -> Expression { expr }
    
    setName: func (=name) {}
    getName: func -> String { name }
    
    setSuffix: func (=suffix) {}
    getSuffix: func -> String { suffix }

    accept: func (visitor: Visitor) {
        visitor visitFunctionCall(this)
    }
    
    debugCondition: func -> Bool {
        false
    }
    
    suggest: func (candidate: FunctionDecl) -> Bool {
        
        if(debugCondition()) "** Got suggestion %s for %s" format(candidate toString(), toString()) println()
        
        if(isMember() && candidate owner == null) {
            //printf("** %s is no fit!, we need something to fit %s\n", candidate toString(), toString())
            return false
        }
        
        score := getScore(candidate)
        if(score > refScore) {
            //"** New high score, %d/%s wins against %d/%s" format(score, candidate toString(), refScore, ref ? ref toString() : "(nil)") println()
            refScore = score
            ref = candidate
            return true
        }
        return false
        
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        //printf("===============================================================\n")
        //printf("     - Resolving call to %s (ref = %s)\n", name, ref ? ref toString() : "(nil)")
        
        if(args size() > 0) {
            trail push(this)
            i := 0
            for(arg in args) {
                response := arg resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    return response
                }
                i += 1
            }
            trail pop(this)
        }
        
        if(expr) {
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                if(res params veryVerbose) printf("Failed to resolve expr %s of call %s, looping\n", expr toString(), toString())
                return response
            }
        }
        
        if(returnType) {
            response := returnType resolve(trail, res)
            if(!response ok()) return response
        }
        
        if(returnArg) {
            response := returnArg resolve(trail, res)
            if(!response ok()) return response
            
            if(returnArg isResolved() && !returnArg instanceOf(AddressOf)) {
                returnArg = returnArg getGenericOperand()
            }
        }
        
        /*
         * Try to resolve the call.
         * 
         * We don't only have to find one definition, we have to find
         * the *best* one. For that, we're sticking to our fun score
         * system. A call can determine the score of a decl, based
         * mostly on the types of the arguments, the suffix, etc.
         * 
         * Since we're looking for the best, we have to do the whole
         * trail from top to bottom
         */
        if(refScore == -1) {
        	if(name == "super") {
				fDecl := trail get(trail find(FunctionDecl)) as FunctionDecl
                superTypeDecl := fDecl owner getSuperRef()
                finalScore: Int
                ref = superTypeDecl getMeta() getFunction(fDecl getName(), null, this, finalScore&)
                if(finalScore == -1) {
                    res wholeAgain(this, "something in our typedecl's functions needs resolving!")
                    return Responses OK
                }
                refScore = 1
				expr = VariableAccess new(superTypeDecl getThisDecl(), token)
        	} else {
        		if(expr == null) {
				    depth := trail size() - 1
				    while(depth >= 0) {
				        node := trail get(depth)
				        node resolveCall(this)
				        depth -= 1
				    }
			    } else if(expr instanceOf(VariableAccess) && expr as VariableAccess getRef() != null && expr as VariableAccess getRef() instanceOf(NamespaceDecl)) {
                    printf("============ [FunctionCall] expr ref is a NamespaceDecl!!\n")
                    expr as VariableAccess getRef() resolveCall(this)
                } else if(expr getType() != null && expr getType() getRef() != null) {
                    if(!expr getType() getRef() instanceOf(TypeDecl)) {
                        message := "No such function %s.%s%s (you can't call methods on generic types! you have to cast them to something sane first)" format(expr getType() getName(), name, getArgsTypesRepr())
                        token throwError(message)
                    }
                    tDecl := expr getType() getRef() as TypeDecl
		            meta := tDecl getMeta()
		            if(meta) {
		                meta resolveCall(this)
		            } else {
		                tDecl resolveCall(this)
		            }
		        }
            }
        }
        
        /*
         * Now resolve return type, generic type arguments, and interfaces
         */
        if(refScore != -1) {
            
            if(!resolveReturnType(trail, res) ok()) {
                res wholeAgain(this, "%s looping because of return type!" format(toString()))
                return Responses OK
            }
            
            if(!handleGenerics(trail, res) ok()) {
                res wholeAgain(this, "%s looping because of generics!" format(toString()))
                return Responses OK
            }
            
            if(!handleInterfaces(trail, res) ok()) {
                res wholeAgain(this, "%s looping because of interfaces!" format(toString()))
                return Responses OK
            }
            
        }
        
        if(typeArgs size() > 0) {
            trail push(this)
            for(typeArg in typeArgs) {
                response := typeArg resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    res wholeAgain(this, "typeArg %s failed to resolve\n" format(typeArg toString()))
                    return Responses OK
                }
            }
            trail pop(this)
        }
        
        unwrapIfNeeded(trail, res)

        if(refScore == -1 && res fatal) {
            message : String
            if(expr && expr getType()) {
                message = "No such function %s.%s%s" format(expr getType() getName(), name, getArgsTypesRepr())
            } else {
                message = "No such function %s%s" format(name, getArgsTypesRepr())
            }
            printf("name = %s, refScore = %d, ref = %s\n",
            	name, refScore, ref ? ref toString() : "(nil)")
            token throwError(message)
        }

        if(refScore == -1) {
            res wholeAgain(this, "%s looping because not resolved!" format(toString()))
            return Responses OK
        }
        
        return Responses OK
        
    }
    
    unwrapIfNeeded: func (trail: Trail, res: Resolver) -> Response {
        
        parent := trail peek()
        
        if(ref == null || ref returnType == null) {
            res wholeAgain(this, "need ref and refType")
            return Responses OK
        }
        
        idx := 2
        while(parent instanceOf(Cast)) {
            parent = trail peek(idx)
            idx += 1
        }
        
        if(ref returnType isGeneric() && !isFriendlyHost(parent)) {
            vDecl := VariableDecl new(getType(), generateTempName("genCall"), token)
            if(!trail addBeforeInScope(this, vDecl)) {
                if(res fatal) token throwError("Couldn't add a " + vDecl toString() + " before a " + toString() + ", trail = " + trail toString())
                res wholeAgain(this, "couldn't add before scope")
                return Responses OK
            }
            
            seq := CommaSequence new(token)
            if(!trail peek() replace(this, seq)) {
                if(res fatal) token throwError("Couldn't replace " + toString() + " with " + seq toString() + ", trail = " + trail toString())
                // FIXME: what if we already added the vDecl?
                res wholeAgain(this, "couldn't unwrap, trail = " + trail toString())
                return Responses OK
            }
            
            // only modify ourselves if we could do the other modifications
            varAcc := VariableAccess new(vDecl, token)
            setReturnArg(varAcc)
            
            seq getBody() add(this)
            seq getBody() add(varAcc)
            
            res wholeAgain(this, "just unwrapped")
        }
        
        return Responses OK
        
    }

	/**
	 * In some cases, a generic function call needs to be unwrapped,
	 * e.g. when it's used as an expression in another call, etc.
	 * However, some nodes are 'friendly' parents to us, e.g.
	 * they handle things themselves and we don't need to unwrap.
	 * @return true if the node is friendly, false if it is not and we
	 * need to unwrap
	 */
    isFriendlyHost: func (node: Node) -> Bool {
        node isScope() ||
		node instanceOf(CommaSequence) ||
		node instanceOf(VariableDecl) ||
		(node instanceOf(BinaryOp) && node as BinaryOp isAssign())
    }
    
    resolveReturnType: func (trail: Trail, res: Resolver) -> Response {
        
        if(returnType != null) return Responses OK
        
        //printf("Resolving returnType of %s (=%s), returnType of ref = %s, isGeneric() = %s, ref of returnType of ref = %s\n", toString(), returnType ? returnType toString() : "(nil)", 
        //    ref returnType toString(), ref returnType isGeneric() toString(), ref returnType getRef() ? ref returnType getRef() toString() : "(nil)")
        
        if(returnType == null && ref != null) {
            if(ref returnType getRef() == null) {
                res wholeAgain(this, "need to know if the return type of our ref is generic.")
                return Responses OK
            }
            
            if(ref returnType isGeneric()) {
                if(res params veryVerbose) printf("\t$$$$ resolving returnType %s for %s\n", ref returnType toString(), toString())
                returnType = resolveTypeArg(ref returnType getName(), trail, res)
                if(returnType == null && res fatal) {
                    token throwError("Not enough info to resolve return type %s of function call\n" format(ref returnType toString()))
                }
            } else {
                returnType = ref returnType clone()
            }
            if(returnType != null && !realTypize(returnType, trail, res)) {
                res wholeAgain(this, "because couldn't properly realTypize return type.")
                returnType = null
            }
            
            if(returnType) {
                res wholeAgain(this, "because of return type %s" format(returnType toString()))
                return Responses OK
            }
        }
        
        if(returnType == null) {
            if(res fatal) token throwError("Couldn't resolve return type of function %s\n" format(toString()))
            return Responses LOOP
        }
        
        //"At the end of resolveReturnType(), the return type of %s is %s" format(toString(), getType() ? getType() toString() : "(nil)") println()
        return Responses OK
        
    }
    
    realTypize: func (type: Type, trail: Trail, res: Resolver) -> Bool {

        //printf("[realTypize] realTypizing type %s in %s\n", type toString(), toString())
        
        if(type instanceOf(BaseType) && type as BaseType typeArgs != null) {
            baseType := type as BaseType
            j := 0
            for(typeArg in baseType typeArgs) {
                //printf("[realTypize] for typeArg %s (ref = %s)\n", typeArg toString(), typeArg getRef() ? typeArg getRef() toString() : "(nil)")
                if(typeArg getRef() == null) {
                    return false // must resolve it before
                }
                //printf("[realTypize] Ref of typeArg %s is a %s (and expr is a %s)\n", typeArg toString(), typeArg getRef() class name, expr ? expr toString() : "(nil)")
                
                // if it's generic-unspecific, it needs to be resolved
                if(typeArg getRef() instanceOf(VariableDecl)) {
                    typeArgName := typeArg getRef() as VariableDecl getName()
                    result := resolveTypeArg(typeArgName, trail, res)
                    //printf("[realTypize] result = %s\n", result ? result toString() : "(nil)")
                    if(result) baseType typeArgs set(j, result)
                }
                j += 1
            }
        }
        
        return true
        
    }
    
    /**
     * Add casts for interfaces arguments
     */
    handleInterfaces: func (trail: Trail, res: Resolver) -> Response {
        
        i := 0
        for(declArg in ref args) {
            if(declArg instanceOf(VarArg)) break
            if(i >= args size()) break
            callArg := args get(i)
            if(declArg getType() == null || declArg getType() getRef() == null ||
               callArg getType() == null || callArg getType() getRef() == null) {
                res wholeAgain(this, "To resolve interface-args, need to resolve declArg and callArg" format(declArg toString(), callArg toString()))
                return Responses OK
            }
            if(declArg getType() getRef() instanceOf(InterfaceDecl)) {
                if(!declArg getType() equals(callArg getType())) {
                    args set(i, Cast new(callArg, declArg getType(), callArg token))
                }
                
            }
            i += 1
        }
        
        return Responses OK
        
    }
    
    /**
     * Resolve type arguments
     */
    handleGenerics: func (trail: Trail, res: Resolver) -> Response {
        
        j := 0
        for(implArg in ref args) {
            if(implArg instanceOf(VarArg)) { j += 1; continue }
            if(implArg getType() == null || !implArg getType() isResolved()) {
                res wholeAgain(this, "need ref arg type"); break // we'll do it later
            }
            if(!implArg getType() isGeneric()) { j += 1; continue }
            
            //printf(" >> Reviewing arg %s in call %s\n", arg toString(), toString())
            
            callArg := args get(j)
            typeResult := callArg getType()
            if(typeResult == null) {
                res wholeAgain(this, "null callArg, need to resolve it first.")
                return Responses OK
            }
            
            isGood := (callArg instanceOf(AddressOf) || typeResult isGeneric())
            if(!isGood) { // FIXME this is probably wrong - what if we want an address's address? etc.
                target : Expression = callArg
                if(!callArg isReferencable()) {
                    varDecl := VariableDecl new(typeResult, generateTempName("genArg"), callArg, nullToken)
                    if(!trail addBeforeInScope(this, varDecl)) {
                        printf("Couldn't add %s before %s, parent is a %s\n", varDecl toString(), toString(), trail peek() toString())
                    }
                    target = VariableAccess new(varDecl, callArg token)
                }
                args set(j, AddressOf new(target, target token))
            
            }
            j += 1
        }
        
        if(typeArgs size() == ref typeArgs size()) {
            return Responses OK // already resolved
        }
        
        //if(res params veryVerbose) printf("\t$$$$ resolving typeArgs of %s (call = %d, ref = %d)\n", toString(), typeArgs size(), ref typeArgs size())
        //if(res params veryVerbose) printf("trail = %s\n", trail toString())
        
        i := typeArgs size()
        while(i < ref typeArgs size()) {
            typeArg := ref typeArgs get(i)
            //if(res params veryVerbose) printf("\t$$$$ resolving typeArg %s\n", typeArg name)
            
            typeResult := resolveTypeArg(typeArg name, trail, res)
            if(typeResult) {
                typeArgs add(VariableAccess new(typeResult getName(), nullToken))
            } else break // typeArgs must be in order
            
            i += 1
        }
        
        for(typeArg in typeArgs) {
            response := typeArg resolve(trail, res)
            if(!response ok()) {
                if(res fatal) {
                    token throwError("Couldn't resolve typeArg %s in call %s" format(typeArg toString(), toString()))
                }
                return response
            }
        }
        
        if(typeArgs size() != ref typeArgs size()) {
            if(res fatal) {
                token throwError("Missing info for type argument %s. Have you forgotten to qualify, e.g. List<Int>?" format(ref typeArgs get(typeArgs size()) getName()))
            }
            res wholeAgain(this, "Looping %s because of typeArgs\n" format(toString()))
        }
        
        return Responses OK
        
    }
    
    resolveTypeArg: func (typeArgName: String, trail: Trail, res: Resolver) -> Type {
        
        //printf("Should resolve typeArg %s in call%s\n", typeArgName, toString())
        
        /* myFunction: func <T> (myArg: T) */
        j := 0
        for(arg in ref args) {
            if(arg type getName() == typeArgName) {
                implArg := args get(j)
                result := implArg getType()
                //printf(" >> Found arg-arg %s for typeArgName %s, returning %s\n", implArg toString(), typeArgName, result toString())
                return result
            }
            j += 1
        }
        
        /* myFunction: func <T> (T: Class) */
        j = 0
        for(arg in ref args) {
            if(arg getName() == typeArgName) {
                implArg := args get(j)
                if(implArg instanceOf(VariableAccess)) {
                    result := BaseType new(implArg as VariableAccess getName(), implArg token)
                    //" >> Found ref-arg %s for typeArgName %s, returning %s" format(implArg toString(), typeArgName, result toString()) println()
                    return result
                } else if(implArg instanceOf(Type)) {
                    return implArg
                }
            }
            j += 1
        }

        /* myFunction: func <T> (myArg: OtherType<T>) */
        for(arg in args) {
            //printf("Looking for typeArg %s in arg's type %s\n", typeArgName, arg getType() toString())
            result := searchInTypeDecl(typeArgName, arg getType())
            if(result) {
                //printf("Found match for arg %s! Hence, result = %s (cause arg = %s)\n", typeArgName, result toString(), arg toString())
                return result
            }
        }

        if(expr != null) {
            if(expr instanceOf(Type)) {
                /* Type<T> myFunction() */
                //printf("Looking for typeArg %s in expr-type %s\n", typeArgName, expr toString())
                result := searchInTypeDecl(typeArgName, expr)
                if(result) {
                    //printf("Found match for arg %s! Hence, result = %s (cause expr = %s)\n", typeArgName, result toString(), expr toString())
                    return result
                }
            } else {
                /* expr: Type<T>; expr myFunction() */
                //printf("Looking for typeArg %s in expr %s\n", typeArgName, expr toString())
                result := searchInTypeDecl(typeArgName, expr getType())
                if(result) {
                    //printf("Found match for arg %s! Hence, result = %s (cause expr type = %s)\n", typeArgName, result toString(), expr getType() toString())
                    return result
                }
            }
        }
        
        idx := trail find(TypeDecl)
        if(idx != -1) {
            tDecl := trail get(idx) as TypeDecl
            for(typeArg in tDecl getTypeArgs()) {
                if(typeArg getName() == typeArgName) {
                    result := BaseType new(typeArgName, token)
                    return result
                }
            }
        }
        
        //printf("Couldn't resolve typeArg %s\n", typeArgName)
        return null
        
    }
    
    searchInTypeDecl: func (typeArgName: String, anyType: Type) -> Type {
        if(anyType == null || anyType getRef() == null) return null
        
        if(!anyType instanceOf(BaseType)) return null
        type := anyType as BaseType
        
        if(!type getRef() instanceOf(TypeDecl)) {
            // only TypeDecl have typeArgs anyway.
            return null
        }
        
        typeRef := type getRef() as TypeDecl
        if(typeRef typeArgs == null) return null
        
        j := 0
        for(arg in typeRef typeArgs) {
            if(arg getName() == typeArgName) {
                if(type typeArgs == null || type typeArgs size() <= j) {
                    continue
                }
                candidate := type typeArgs get(j)
                ref := candidate getRef()
                if(ref == null) return null
                result: Type = null
                //printf("Found candidate %s for typeArg %s\n", candidate toString(), typeArgName)
                if(ref instanceOf(TypeDecl)) {
                    // resolves to a known type
                    result = candidate getRef() as TypeDecl getInstanceType()
                } else {
                    // resolves to an access to another generic type
                    result = BaseType new(ref as VariableDecl getName(), token)
                }
                return result
            }
            j += 1
        }
        return null
    }
    
    /**
     * @return the score of decl, respective to this function call.
     * This is used when resolving function calls, so that the function
     * decl with the highest score is chosen as a reference.
     */
    getScore: func (decl: FunctionDecl) -> Int {
        score := 0
        
        declArgs := decl args
        if(matchesArgs(decl)) {
            score += 10
        } else {
            return 0
        }
        
        if(declArgs size() == 0) return score
        
        declIter : Iterator<Argument> = declArgs iterator()
        callIter : Iterator<Expression> = args iterator()
        
        while(callIter hasNext() && declIter hasNext()) {
            declArg := declIter next()
            callArg := callIter next()
            // avoid null types
            if(declArg instanceOf(VarArg)) break
            if(declArg getType() == null) return -1
            if(callArg getType() == null) return -1
            if(declArg type equals(callArg getType())) {
                score += 10
            }
        }
        
        return score
    }
    
    /**
     * Returns true if decl has a signature compatible with this function call
     */
    matchesArgs: func (decl: FunctionDecl) -> Bool {
        declArgs := decl args size()
        callArgs := args size()

        // same number of args
        if(declArgs == callArgs) {
            return true
        }
        
        // or, at least one arg, and the last is a varArg
        if(declArgs > 0) {
            last := decl args last()
            // and less fixed decl args than call args ;)
            if(last instanceOf(VarArg) && declArgs - 1 <= callArgs) {
                return true
            }
        }
        
        return false
    }
    
    getType: func -> Type { returnType }
    
    isMember: func -> Bool {
        (expr != null) &&
        !(expr instanceOf(VariableAccess) &&
          expr as VariableAccess getRef() != null &&
          expr as VariableAccess getRef() instanceOf(NamespaceDecl)
        )
    }
    
    getArgsRepr: func -> String {
        sb := Buffer new()
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
    
    getArgsTypesRepr: func -> String {
        sb := Buffer new()
        sb append("(")
        isFirst := true
        for(arg in args) {
            if(!isFirst) sb append(", ")
            sb append(arg getType() ? arg getType() toString() : "<unknown type>")
            if(isFirst) isFirst = false
        }
        sb append(")")
        return sb toString()
    }
    
    toString: func -> String {
        (expr ? expr toString() + " " : "") + (ref ? ref getName() : name) + getArgsRepr()
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        if(oldie == expr) {
            expr = kiddo;
            return true;
        }
        
        return (args replace(oldie, kiddo) != null)
    }
    
    setReturnArg: func (=returnArg) {}
    getReturnArg: func -> Expression { returnArg }
    
    getRef: func -> FunctionDecl { ref }
    setRef: func (=ref) { refScore = 0; /* or it'll keep trying to resolve it =) */ }

	getArguments: func ->  ArrayList<Expression> { args }

}
