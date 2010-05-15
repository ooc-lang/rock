import ../frontend/[Token, BuildParams]
import BinaryOp, Visitor, Expression, VariableDecl, FunctionDecl, TypeDecl,
	   Declaration, Type, Node, ClassDecl, NamespaceDecl, EnumDecl, PropertyDecl, FunctionCall
import tinker/[Resolver, Response, Trail]

VariableAccess: class extends Expression {

    expr: Expression
    name: String
    
    ref: Declaration
    
    init: func ~variableAccess (.name, .token) {
        init(null, name, token)
    }
    
    init: func ~variableAccessWithExpr (=expr, =name, .token) {
        super(token)
    }
    
    init: func ~varDecl (varDecl: VariableDecl, .token) {
        super(token)
        name = varDecl getName()
        ref = varDecl
    }
    
    init: func ~typeAccess (type: Type, .token) {
        super(token)
        name = type getName()
        ref = type getRef()
    }
    
    accept: func (visitor: Visitor) {
        visitor visitVariableAccess(this)
    }
    
    // It's just an access, it has no side-effects whatsoever
    hasSideEffects : func -> Bool { false }
    
    debugCondition: func -> Bool { false }
    
    suggest: func (node: Node) -> Bool {
        if(node instanceOf(VariableDecl)) {
			candidate := node as VariableDecl
		    // if we're accessing a member, we're expecting the candidate
		    // to belong to a TypeDecl..
		    if(isMember() && candidate owner == null) {
                printf("%s is no fit!, we need something to fit %s\n", candidate toString(), toString())
		        return false
		    }
		    
		    ref = candidate
            if(isMember() && candidate owner isMeta) {
                expr = VariableAccess new(candidate owner getNonMeta() getInstanceType(), candidate token)
            }
            
		    return true
	    } else if(node instanceOf(FunctionDecl)) {
			candidate := node as FunctionDecl
		    // if we're accessing a member, we're expecting the candidate
		    // to belong to a TypeDecl..
		    if((expr != null) && (candidate owner == null)) {
		        printf("%s is no fit!, we need something to fit %s\n", candidate toString(), toString())
		        return false
		    }
		    
		    ref = candidate
		    return true
	    } else if(node instanceOf(TypeDecl) || node instanceOf(NamespaceDecl)) {
			ref = node
            return true
	    }
	    return false
    }
    
    isResolved: func -> Bool { ref != null && getType() != null }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if(debugCondition()) {
            "%s is of type %s\n" format(name, getType() ? getType() toString() : "(nil)") println()
        }
        
        if(expr) {
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) return response
            //printf("Resolved expr, type = %s\n", expr getType() ? expr getType() toString() : "(nil)")
        }
        
        if(expr && name == "class") {
            if(expr getType() == null || expr getType() getRef() == null) {
                res wholeAgain(this, "expr type or expr type ref is null")
                return Responses OK
            }
            if(!expr getType() getRef() instanceOf(ClassDecl)) {
                name = expr getType() getName()
                ref = expr getType() getRef()
                expr = null
            }
        }
        
        /*
         * Try to resolve the access from the expr
         */
        if(!ref && expr) {
            if(expr instanceOf(VariableAccess) && expr as VariableAccess getRef() != null \
              && expr as VariableAccess getRef() instanceOf(NamespaceDecl)) {
                expr as VariableAccess getRef() resolveAccess(this, res, trail)
            } else {
                exprType := expr getType()
                if(exprType == null) {
                    res wholeAgain(this, "expr's type isn't resolved yet, and it's needed to resolve the access")
                    return Responses OK
                }
                //printf("Null ref and non-null expr (%s), looking in type %s\n", expr toString(), exprType toString())
                typeDecl := exprType getRef()
                if(!typeDecl) {
                    if(res fatal) expr token throwError("Can't resolve type %s" format(expr getType() toString()))
                    res wholeAgain(this, "     - access to %s%s still not resolved, looping (ref = %s)\n" \
                      format(expr ? (expr toString() + "->") : "", name, ref ? ref toString() : "(nil)"))
                    return Responses OK
                }
                typeDecl resolveAccess(this, res, trail)
            }
        }
        
        /*
         * Try to resolve the access from the trail
         * 
         * It's far simpler than resolving a function call, we just
         * explore the trail from top to bottom and retain the first match.
         */
        if(!ref && !expr) {
            depth := trail size() - 1
            while(depth >= 0) {
                node := trail get(depth)
                if(node instanceOf(TypeDecl)) {
                    tDecl := node as TypeDecl
                    if(tDecl isMeta) node = tDecl getNonMeta()
                }
                node resolveAccess(this, res, trail)
                
                if(ref) {
                    // only accesses to variable decls need to be partialed (not type decls)
                    if(ref instanceOf(VariableDecl) && expr == null) {
                        closureIndex := trail find(FunctionDecl)
                        if(closureIndex > depth) { // if it's not found (-1), this will be false anyway
                            closure := trail get(closureIndex, FunctionDecl)
                            if(closure isAnon()) {
                                closure markForPartialing(ref as VariableDecl)
                            }
                        }
                    }
                    break // break on first match
                }
                depth -= 1
            }
        }

        // Simple property access? Replace myself with a getter call.
        if(ref && ref instanceOf(PropertyDecl)) {
            // Make sure we're not in a getter/setter yet (the trail would
            // contain `ref` then)
            if(ref as PropertyDecl inOuterSpace(trail)) {
                // Test that we're not part of an assignment (which will be replaced by a setter call)
                // TODO: This should be nicer.
                if(!(trail peek() instanceOf(BinaryOp) && trail peek() as BinaryOp type == OpTypes ass)) {
                    property := ref as PropertyDecl
                    fCall := FunctionCall new(expr, property getGetterName(), token)
                    trail peek() replace(this, fCall)
                    return Responses OK
                }
            } else {
                // We are in a setter/getter and we're having a variable access. That means
                // the property is not virtual.
                ref as PropertyDecl setVirtual(false) 
            }
        }
        
        if(!ref) {
            if(res fatal) {
                println("trail = " + trail toString())
                token throwError("No such variable %s" format(toString()))
            }
            if(res params veryVerbose) {
                printf("     - access to %s%s still not resolved, looping (ref = %s)\n", \
                expr ? (expr toString() + "->") : "", name, ref ? ref toString() : "(nil)")
            }
            res wholeAgain(this, "Couldn't resolve %s" format(toString()))
        }
        
        return Responses OK
        
    }
    
    getRef: func -> Declaration { ref }
    
    getType: func -> Type {
           
        if(!ref) return null
        if(ref instanceOf(Expression)) {
            return ref as Expression getType()
        }
        return null
    }
    
    isMember: func -> Bool {
        (expr != null) &&
        !(expr instanceOf(VariableAccess) &&
          expr as VariableAccess getRef() != null &&
          expr as VariableAccess getRef() instanceOf(NamespaceDecl)
        )
    }
    
    getName: func -> String { name }
    
    toString: func -> String {
        (expr && expr getType()) ? (expr getType() toString() + "." + name) : name
    }
    
    isReferencable: func -> Bool { true }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo; true
            case => false
        }
    }

	setRef: func(ref: Declaration) {
        if(name == "String") {
            printf("String been set ref to %s, a %s\n", ref toString(), ref class name)
        }
		this ref = ref
	}

}
