import structs/[ArrayList, List, HashMap]
import ../frontend/[Token, BuildParams]
import Expression, Type, Visitor, Declaration, VariableDecl, ClassDecl,
    FunctionDecl, FunctionCall, Module, VariableAccess, Node
import tinker/[Resolver, Response, Trail]

TypeDecl: abstract class extends Declaration {

    name: String
    externName: String = null

    typeArgs := ArrayList<VariableDecl> new()

    variables := HashMap<VariableDecl> new()
    functions := HashMap<FunctionDecl> new()

    thisDecl : VariableDecl

    instanceType: Type
    type: Type
    superType: Type = null
    
    module: Module = null
    
    isMeta := false
    meta : TypeDecl = null
    nonMeta : TypeDecl = null
    
    init: func ~typeDeclNoSuper (=name, .token) {
        super(token)
        type = BaseType new("Class", token)
        instanceType = BaseType new(name, token)
        instanceType as BaseType ref = this
        thisDecl = VariableDecl new(instanceType, "this", nullToken)
        
        if(!isMeta) {
            meta = ClassDecl new(name + "Class", null, true, token)
            meta nonMeta = this
            meta thisDecl = this thisDecl
            meta setSuperType(BaseType new("Class", nullToken))
            
            // if we access to "Dog", we access to an object of type "DogClass"
            type = meta getInstanceType()
            type as BaseType ref = meta
        }
        
        if(!isObjectClass()) {
            // by default, everyone inherits from object
            setSuperType(BaseType new("Object", token))
        }
    }
    
    init: func ~typeDecl (.name, =superType, .token) {
        this(name, token)
        setSuperType(superType)
    }
    
    setSuperType: func(=superType) {
        if(!this isMeta && superType != null) {
            // TODO: there's probably a better way, but this works fine =)
            if(superType getName() == "Object" && name != "Class") {
                meta setSuperType(BaseType new("ClassClass", nullToken))
            } else {
                meta setSuperType(BaseType new(this superType getName() + "Class", nullToken))
            }
        }
    }
    
    addTypeArg: func (typeArg: VariableDecl) -> Bool {
        typeArg owner = this
        getTypeArgs() add(typeArg)
        variables put(typeArg getName(), typeArg)
        true
    }
    
    isObjectClass: func -> Bool {
        name equals("Object") || name equals("ObjectClass")
    }
    
    isClassClass: func -> Bool {
        name equals("Class") || name equals("ClassClass")
    }
    
    isRootClass: func -> Bool {
        isObjectClass() || isClassClass()
    }
    
    addVariable: func (vDecl: VariableDecl) {
        if(vDecl isStatic && !isMeta) {
            meta addVariable(vDecl)
        } else {
            variables put(vDecl name, vDecl)
            vDecl owner = this
        }
    }

	hashName: func (name, suffix: String) -> String {
		suffix ? "%s~%s" format(name, suffix) : name
	}

	hashName: func ~fromFuncDecl (fDecl: FunctionDecl) -> String {
		hashName(fDecl getName(), fDecl getSuffix())
	}
    
    addFunction: func (fDecl: FunctionDecl) {
        if(isMeta) {
            functions put(hashName(fDecl), fDecl)
        } else {
            meta addFunction(fDecl)
        }
        fDecl owner = this
    }

	removeFunction: func(fDecl: FunctionDecl) {
		functions remove(fDecl getName())
	}
    
    getFunction: func (fName, fSuffix: String) -> FunctionDecl {
    
    	// quick lookup, if we're lucky (exact suffix or no suffix)
        fDecl : FunctionDecl = null
        fDecl = functions get(hashName(fName, fSuffix))
		if(fDecl) return fDecl

		// slow lookup, if we have a vague query
		if(fSuffix == null) {
			for(f in functions) {
				// returns the first match.. is it useful?
				if(f getName() == fName) {
					return fDecl
				}
			}
		}
        return null
    }
    
    getVariable: func (vName: String) -> VariableDecl {
    	{
	        result := variables get(vName)
	        if(result) return result
	    }
        
        if(isMeta) {
			result := getNonMeta() getVariable(vName)
			if(result) return result
        }

        if(getSuperRef()) {
			return getSuperRef() getVariable(vName)
        }
    }
    
    getVariables: func -> HashMap<VariableDecl> { variables }
    getFunctions: func -> HashMap<VariableDecl> { functions }
    
    underName: func -> String {
        
        // TODO underize it.
        /*
        if(module != null) {
            printf("module fullName = %s\n", module fullName)
            printf("module packageName = %s\n", module packageName)
            printf("externName = %s\n", externName)
            printf("module packageName isEmpty() = %d\n", module packageName isEmpty())
            printf("isExtern = %d\n", isExtern())
        }
        */
        if(module != null && !module packageName isEmpty() && !isExtern()) {
			return module packageName + "__" + name
        }
            
		return name       
    }
    
	getTypeArgs: func -> List<VariableDecl> { isMeta ? getNonMeta() typeArgs : typeArgs }

    getName: func -> String { name }
    
    getExternName: func -> String {
        return (externName && !externName isEmpty()) ? externName : name
    }
    
    isExtern: func -> Bool { externName != null }
    
    getSuperRef: func -> TypeDecl {
        superType ? superType getRef() : null
    }
    
    getFunction: func ~call (call: FunctionCall) -> FunctionDecl {
        return getFunction(call name, call suffix, call)
    }
    
    getFunction: func ~nameSuffCall (name, suffix: String, call: FunctionCall) -> FunctionDecl {
        return getFunction(name, suffix, call, true);
    }
    
    getFunction: func ~nameSuffCallRec (name, suffix: String, call: FunctionCall, recursive: Bool) -> FunctionDecl {
        return getFunction(name, suffix, call, recursive, 0, null)
    }
    
    getFunction: func ~real (name, suffix: String, call: FunctionCall,
        recursive: Bool, bestScore: Int, bestMatch: FunctionDecl) -> FunctionDecl {
            
        for(fDecl: FunctionDecl in functions) {
            if(fDecl name equals(name) && (suffix == null || fDecl suffix equals(suffix))) {
                if(!call) return fDecl
                score := call getScore(fDecl)
                if(score == -1) return null
                if(score > bestScore) {
                    bestScore = score
                    bestMatch = fDecl
                }
            }
        }
        
        if(recursive && getSuperRef() != null) {
            return getSuperRef() getFunction(name, suffix, call, true, bestScore, bestMatch)
        }
        return bestMatch
        
    }

    getModule: func -> Module { module }
    getType: func -> Type { type }
    getInstanceType: func -> Type { instanceType }
    getThisDecl: func -> VariableDecl { thisDecl }

    isResolved: func -> Bool { false }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        
        //if(res params verbose) printf("====== Resolving type decl %s\n", toString())
        
        {
            response := type resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        if(superType) {
            response := superType resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        for(typeArg in getTypeArgs()) {
            response := typeArg resolve(trail, res)
            if(!response ok()) {
                if(res params verbose) printf("Response of typeArg %s = %s\n", typeArg toString(), response toString())
                trail pop(this)
                return response
            }
        }

        for(vDecl in variables) {
            response := vDecl resolve(trail, res)
            if(!response ok()) {
                if(res params verbose) printf("Response of vDecl %s = %s\n", vDecl toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        for(fDecl in functions) {
            response := fDecl resolve(trail, res)
            if(!response ok()) {
                if(res params verbose) printf("Response of fDecl %s = %s\n", fDecl toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        if(meta) {
            meta module = module
            response := meta resolve(trail, res)
            if(!response ok()) {
                if(res params verbose) printf("-- %s, meta of %s, isn't resolved, looping.\n", meta toString(), toString())
                trail pop(this)
                return response
            }
        }
        
        trail pop(this)
        
        return Responses OK
        
    }
    
    resolveType: func (type: BaseType) {
        
        if(type getName() == "This") {
            if(type suggest(getNonMeta() ? getNonMeta() : this)) return
        }
        
        //printf("** Looking for type %s in func %s with %d type args\n", type name, toString(), getTypeArgs() size())
        for(typeArg: VariableDecl in getTypeArgs()) {
            //printf("*** For typeArg %s\n", typeArg name)
            if(typeArg name == type name) {
                //printf("***** Found match for %s in function decl %s\n", type name, toString())
                type suggest(typeArg)
                break
            }
        }
        
    }

    resolveAccess: func (access: VariableAccess) {
        
        //printf("? Looking for variable %s in %s\n", access name, name)
        if(access getName() == "This") {
            if(access suggest(getNonMeta() ? getNonMeta() : this)) return
        }
        
        vDecl := variables get(access name)
        if(vDecl) {
            //"&&&&&&&& Found vDecl %s for %s" format(vDecl toString(), access name) println()
            if(access suggest(vDecl)) {
            	if(access expr == null) {
	                varAcc := VariableAccess new("this", nullToken)
	                access expr = varAcc
                }
                return
            }
        }

		fDecl := getFunction(access name, null, null)
		if(fDecl) {
            //"&&&&&&&& Found fDecl %s for %s" format(fDecl toString(), access name) println()
            if(access suggest(fDecl)) {
            	if(access expr == null) {
	                //varAcc := VariableAccess new("this", nullToken)
	                //access expr = varAcc
                }
                return
            }
		}
		
        if(getSuperRef() != null) {
        	//FIXME: should return here if success
            getSuperRef() resolveAccess(access)
        }
        
        // look in type arguments
        for(typeArg in getTypeArgs()) {
            if(access name == typeArg name) {
                if(access suggest(typeArg) && access expr == null) {
                    varAcc := VariableAccess new("this", nullToken)
                    access expr = varAcc
                    return
                }
            }
        }
        
    }
    
    resolveCall: func (call : FunctionCall) {

		//printf("\n====> Search %s in %s\n", call toString(), name)
        //for(f in functions) {
        //    printf("  - Got %s!\n", f toString())
        //}
        
        fDecl := getFunction(call)
        if(fDecl) {
            //"    \\o/ Found fDecl for %s, it's %s" format(call name, fDecl toString()) println()
            if(call suggest(fDecl)) {
	            if(call getExpr() == null) {
	            	call setExpr(VariableAccess new("this", call token))
            	}
            	//"   returning..." println()
	            return
            }
        } else if(getSuperRef() != null) {
            //printf("  <== going in superRef %s\n", getSuperRef() toString())
            getSuperRef() resolveCall(call)
        }
        
    }
    
    inheritsFrom: func (tDecl: TypeDecl) -> Bool {
        superRef := getSuperRef()
        if(superRef != null) {
        	if(superRef == tDecl) return true
	        return superRef inheritsFrom(tDecl)
        }
        
        return false
    }
    
    toString: func -> String {
        class name + ' ' + name
    }
    
    getMeta: func -> This { meta }
    getNonMeta: func -> This { nonMeta }

}

BuiltinType: class extends TypeDecl {
    
    init: func ~builtinType (.name, .token) {
        super(name, null, token)
    }
    
    underName: func -> String { name }
    
    accept: func (v: Visitor) { /* yeah, right. */ }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
}

