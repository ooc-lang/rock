import structs/ArrayList
import ../frontend/[Token, BuildParams]
import Visitor, Expression, FunctionDecl, Argument, Type, VariableAccess,
       TypeDecl, Node, VariableDecl
import tinker/[Response, Resolver, Trail]

FunctionCall: class extends Expression {

    expr: Expression
    name, suffix = null : String
    typeArgs := ArrayList<Expression> new()
    returnArg : Expression = null
    args := ArrayList<Expression> new()    
    
    ref = null : FunctionDecl
    refScore := -1
    
    init: func ~funcCall (=name, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitFunctionCall(this)
    }
    
    suggest: func (candidate: FunctionDecl) -> Bool {
        
        //"Got suggestion %s for %s" format(candidate toString(), toString()) println()
        if((expr != null) && (candidate owner == null)) {
            //printf("%s is no fit!, we need something to fit %s\n", candidate toString(), toString())
            return false
        }
        
        score := getScore(candidate)
        if(score > refScore) {
            //"New high score, %d/%s wins against %d/%s" format(score, candidate toString(), refScore, ref ? ref toString() : "(nil)") println()
            refScore = score
            ref = candidate
            return true
        }
        return false
        
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        //printf("     - Resolving call to %s (ref = %s)\n", name, ref ? ref toString() : "(nil)")
        
        if(args size() > 0) {
            trail push(this)
            for(arg in args) {
                //printf("Resolving arg %s\n", arg toString())
                response := arg resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    //printf(" -- Failed, looping.\n")
                    return response
                }
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
                meta := expr getType() getRef() as TypeDecl getMeta()
                if(meta) {
                    meta resolveCall(this)
                } else {
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
            handleGenerics(trail, res)
        }
        
        if(typeArgs size() > 0) {
            trail push(this)
            for(typeArg in typeArgs) {
                if(res params verbose) printf("Resolving typeArg %s\n", typeArg toString())
                response := typeArg resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    if(res params verbose) printf(" -- Failed, looping.\n")
                    return response
                }
            }
            trail pop(this)
        }

        if(refScore == -1 && res fatal) {
            token throwError("No such function %s" format(name))
        }
        
        return refScore != -1 ? Responses OK : Responses LOOP
        
    }
    
    /**
     * Resolve type arguments
     */
    handleGenerics: func (trail: Trail, res: Resolver) {
        
        
        if(typeArgs size() == ref typeArgs size()) {
            return // already resolved
        }
        
        if(res params verbose) printf("\t$$$$ resolving typeArgs of %s (call = %d, ref = %d)\n", toString(), typeArgs size(), ref typeArgs size())
        if(res params verbose) printf("trail = %s\n", trail toString())
        
        i := typeArgs size()
        while(i < ref typeArgs size()) {
            typeArg := ref typeArgs get(i)
            if(res params verbose) printf("\t$$$$ resolving typeArg %s\n", typeArg name)
            
            /* myFunction: func <T> (myArg: T) */
            j := 0
            for(arg in ref args) {
                if(arg type getName() == typeArg name) {
                    implArg := args get(j)
                    typeResult := implArg getType()
                    if(res params verbose) printf("\t$$=- found match in arg %s of type %s\n", arg toString(), typeResult toString())
                    typeArgs add(VariableAccess new(typeResult, nullToken))
                    
                    if(!implArg isReferencable()) {
                        varDecl := VariableDecl new(typeResult, generateTempName("genArg"), args get(j), nullToken)
                        
                        if(!trail addBeforeInScope(this, varDecl)) {
                            printf("Couldn't add %s before %s, parent is a %s\n", varDecl toString(), toString(), trail peek() toString())
                        }
                        args set(j, VariableAccess new(varDecl, implArg token))
                    }
                    
                    break
                }
                j += 1
            }
            
            i += 1
        }
        
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
    
    getType: func -> Type { ref ? ref returnType : null }
    
    isMember: func -> Bool { expr != null }
    
    toString: func -> String {
        name +"()"
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

}
