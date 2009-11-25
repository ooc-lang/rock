import structs/ArrayList
import ../frontend/Token
import Visitor, Expression, FunctionDecl, Argument, Type
import tinker/[Response, Resolver, Trail]

FunctionCall: class extends Expression {

    expr: Expression
    name, suffix = null : String
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
        
        "Got suggestion %s for %s" format(candidate toString(), toString()) println()
        
        score := getScore(candidate)
        if(score > refScore) {
            "New high score, %d wins against %d/%s" format(score, refScore, ref ? ref toString() : "(nil)") println()
            refScore = score
            ref = candidate
            return true
        }
        return false
        
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        printf("     - Resolving call to %s (ref = %s)\n", name, ref ? ref toString() : "(nil)")
        
        if(args size() > 0) {
            trail push(this)
            for(arg in args) {
                printf("Resolving arg %s\n", arg toString())
                response := arg resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    printf(" -- Failed, looping.\n")
                    return response
                }
            }
            trail pop(this)
        }
        
        if(expr) {
            printf("Resolving expr %s\n", expr toString())
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                printf(" -- Failed, looping..")
                return response
            }
            //printf("Resolved expr, type = %s\n", expr getType() ? expr getType() toString() : "(nil)")
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
                printf("Trying to resolve %s from node %s\n", toString(), node toString())
                node resolveCall(this)
                depth -= 1
            }
            if(expr && expr getType() && expr getType() getRef()) {
                expr getType() getRef() resolveCall(this)
            }
        }
        
        return refScore != -1 ? Responses OK : Responses LOOP
        
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
            //if(!declArg type) return -1
            //if(!callArg type) return -1
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

}
