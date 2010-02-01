import structs/ArrayList, text/StringBuffer
import ../frontend/[Token, BuildParams]
import Visitor, Expression, FunctionDecl, Argument, Type, VariableAccess,
       TypeDecl, Node, VariableDecl, AddressOf, CommaSequence, BinaryOp
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

    accept: func (visitor: Visitor) {
        visitor visitFunctionCall(this)
    }
    
    suggest: func (candidate: FunctionDecl) -> Bool {
        
        //"** Got suggestion %s for %s" format(candidate toString(), toString()) println()
        if((expr != null) && (candidate owner == null)) {
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
                //printf("Resolving arg %s\n", arg toString())
                response := arg resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    //printf(" -- Failed, looping.\n")
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
                if(res params verbose) printf("Failed to resolve expr %s of call %s, looping\n", expr toString(), toString())
                return response
            }
        }
        
        if(returnType) {
            response := returnType resolve(trail, res)
            if(!response ok()) return response
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
            depth := trail size() - 1
            while(depth >= 0) {
                node := trail get(depth)
                node resolveCall(this)
                depth -= 1
            }
            if(expr != null && expr getType() != null && expr getType() getRef() != null) {
                tDecl := expr getType() getRef() as TypeDecl
                meta := tDecl getMeta()
                if(meta) {
                    meta resolveCall(this)
                } else {
                    tDecl resolveCall(this)
                    //printf("--> %s has no meta, not resolving.\n", expr getType() getRef() toString())
                }
            //} else {
                //printf("<-- Apparently, there's no expr for %s (or is there? %s)\n", toString(), expr ? expr toString() : "no.")
            }
        }
        
        /*
         * Now resolve generic type arguments
         */
        if(refScore != -1) {
            
            if(!resolveReturnType(trail, res) ok()) {
                if(res params verbose) "%s looping because of return type!" format(toString()) println()
                return Responses LOOP
            }
            
            if(!handleGenerics(trail, res) ok()) {
                if(res params verbose) "%s looping because of generics!" format(toString()) println()
                return Responses LOOP
            }
        }
        
        if(typeArgs size() > 0) {
            trail push(this)
            for(typeArg in typeArgs) {
                if(typeArg isResolved()) continue
                //if(res params verbose) printf("Resolving typeArg %s\n", typeArg toString())
                response := typeArg resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    //if(res params verbose) printf(" -- Failed, looping.\n")
                    return response
                }
            }
            trail pop(this)
        }
        
        unwrapIfNeeded(trail, res)

        if(refScore == -1 && res fatal) {
            message : String
            if(expr && expr getType()) {
                message = "No such function %s.%s%s" format(expr getType() getName(), name, getArgsRepr())
            } else {
                message = "No such function %s%s" format(name, getArgsRepr())
            }
            token throwError(message)
        }

        if(refScore == -1) {
            if(res params verbose) "%s looping because not resolved!" format(toString()) println()
            return Responses LOOP
        }
        
        return Responses OK
        
    }
    
    unwrapIfNeeded: func (trail: Trail, res: Resolver) -> Response {
        
        parent := trail peek()
        
        if(ref == null || ref returnType == null) {
            if(res params verbose) printf("LOOPing %s because ref = null, or ref returnType == null\n", toString())
            return Responses LOOP // evil! should take fatal into account
        }
        
        if(ref returnType isGeneric() && !isFriendlyHost(parent)) {
            //printf("OHMAGAD a generic-returning function (say, %s) in a %s!!!\n", toString(), parent toString())
            vDecl := VariableDecl new(getType(), generateTempName("genCall"), token)
            if(!trail addBeforeInScope(this, vDecl)) {
                token throwError("Couldn't add a " + vDecl toString() + " before a " + toString() + ", trail = " + trail toString())
            }
            varAcc := VariableAccess new(vDecl, token)
            setReturnArg(varAcc)
            seq := CommaSequence new(token)
            seq getBody() add(this)
            seq getBody() add(varAcc)
            //printf("Just unwrapped %s into var %s\n", toString(), varAcc toString())
            if(!parent replace(this, seq)) {
                token throwError("Couldn't replace " + toString() + " with " + seq toString() + ", trail = " + trail toString())
            }
        }
        
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
        //  ref returnType toString(), ref returnType isGeneric() toString(), ref returnType getRef() ? ref returnType getRef() toString() : "(nil)")
        
        if(returnType == null && ref != null) {
            if(ref returnType getRef() == null) {
                //ref returnType resolve(trail, res)
                res wholeAgain(this, "need to know if the return type of our ref is generic.")
                return Responses OK
            }
            
            if(ref returnType isGeneric()) {
                /*if(res params verbose)*/ printf("\t$$$$ resolving returnType %s\n", ref returnType toString())
                returnType = resolveTypeArg(ref returnType getName(), trail, res)
                if(returnType == null && res fatal) {
                    token throwError("Not enough info to resolve return type %s of function call\n" format(ref returnType toString()))
                }
            } else {
                returnType = ref returnType
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
        
        //"At the end of resolveReturnType(), the return type of %s is %s" format(toString(), getType() ? getType() toString() : "null") println()
        return Responses OK
        
    }
    
    /**
     * Resolve type arguments
     */
    handleGenerics: func (trail: Trail, res: Resolver) -> Response {
        
        if(typeArgs size() == ref typeArgs size()) {
            return Responses OK // already resolved
        }
        
        //if(res params verbose) printf("\t$$$$ resolving typeArgs of %s (call = %d, ref = %d)\n", toString(), typeArgs size(), ref typeArgs size())
        //if(res params verbose) printf("trail = %s\n", trail toString())
        
        i := typeArgs size()
        while(i < ref typeArgs size()) {
            typeArg := ref typeArgs get(i)
            //if(res params verbose) printf("\t$$$$ resolving typeArg %s\n", typeArg name)
            
            typeResult := resolveTypeArg(typeArg name, trail, res)
            if(typeResult) {
                typeArgs add(VariableAccess new(typeResult, nullToken))
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
                token throwError("Couldn't figure out generic type %s in call %s" format(ref typeArgs get(typeArgs size()) toString(), toString()))
            }
            res wholeAgain("Looping %s because of typeArgs\n", toString())
        }
        
        return Responses OK
        
    }
    
    resolveTypeArg: func (typeArgName: String, trail: Trail, res: Resolver) -> Type {
        
        printf("Should resolve typeArg %s\n", typeArgName)
        
        /* myFunction: func <T> (myArg: T) */
        j := 0
        for(arg in ref args) {
            if(arg type getName() == typeArgName) {
                implArg := args get(j)
                typeResult := implArg getType()
                if(res params verbose) printf("\t$$=- found match in arg %s of type %s\n", arg toString(), typeResult toString())
                
                isGood := (implArg instanceOf(AddressOf) || implArg getType() isGeneric())
                
                // if AdressOf, the job's done. If it's not referencable, we need to unwrap it!
                if(!isGood) { // FIXME this is probably wrong - what if we want an address's address? etc.
                    printf("&-ing implArg %s\n", implArg toString())
                    
                    target : Expression = implArg
                    if(!implArg isReferencable()) {
                        varDecl := VariableDecl new(typeResult, generateTempName("genArg"), args get(j), nullToken)
                        
                        if(!trail addBeforeInScope(this, varDecl)) {
                            printf("Couldn't add %s before %s, parent is a %s\n", varDecl toString(), toString(), trail peek() toString())
                        }
                        target = VariableAccess new(varDecl, implArg token)
                    }
                    args set(j, AddressOf new(target, target token))
                
                }
                
                return typeResult
            }
            j += 1
        }
        
        /* myFunction: func <T> (T: Class) */
        j = 0
        for(arg in ref args) {
            if(arg getName() == typeArgName) {
                implArg := args get(j)
                result := BaseType new(implArg as VariableAccess getName(), implArg token)
                //" >> Found ref-arg %s for typeArgName %s, returning %s" format(implArg toString(), typeArgName, result toString()) println()
                return result
            }
            j += 1
        }
        
        /* expr: Type<T>; expr myFunction() */
        j = 0
        if(expr != null && expr getType() != null && expr getType() instanceOf(BaseType) && expr getType() getRef() != null) {
            printf("Looking for typeArg %s in expr %s\n", typeArgName, expr toString())
            exprType := expr getType() as BaseType
            ref := exprType getRef() as TypeDecl
            for(arg in ref typeArgs) {
                if(arg getName() == typeArgName) {
                    candidate := exprType typeArgs get(j)
                    ref := candidate getRef()
                    result : Type = null
                    if(ref instanceOf(TypeDecl)) {
                        result = candidate getRef() as TypeDecl getInstanceType()
                    } else {
                        //result = ref getType()
                        result = BaseType new(ref as VariableDecl getName(), token)
                    }
                    printf("Found match for arg %s! it's %s. Hence, result = %s (cause expr type = %s)\n", typeArgName, candidate toString(), result toString(), exprType toString())
                    return result
                }
            }
            j += 1
        }
        
        printf("Couldn't resolve typeArg %s\n", typeArgName)
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
    
    isMember: func -> Bool { expr != null }
    
    getArgsRepr: func -> String {
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
    setRef: func (=ref) { refScore = 0 /* or it'll keep trying to resolve it =) */ }

	getArguments: func ->  ArrayList<Expression> { args }

}
