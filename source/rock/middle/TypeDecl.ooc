import structs/[ArrayList, List, HashMap]
import ../frontend/[Token, BuildParams]
import text/Buffer
import Expression, Type, Visitor, Declaration, VariableDecl, ClassDecl,
    FunctionDecl, FunctionCall, Module, VariableAccess, Node,
    InterfaceImpl, Version
import tinker/[Resolver, Response, Trail]

TypeDecl: abstract class extends Declaration {

    name: String
    externName: String = null

    typeArgs := ArrayList<VariableDecl> new()

    variables := HashMap<String, VariableDecl> new()
    functions := HashMap<String, FunctionDecl> new()
    
    interfaceTypes := ArrayList<Type> new()
    interfaceDecls := ArrayList<InterfaceImpl> new()

    thisDecl, thisRefDecl: VariableDecl

    instanceType: Type
    type: Type
    superType: Type = null
    
    module: Module = null
    
    isMeta := false
    meta : ClassDecl = null
    nonMeta : TypeDecl = null
    
    verzion: VersionSpec = null
    
    _finishedGhosting := false
    
    init: func ~typeDeclNoSuper (=name, .token) {
        super(token)
        type = BaseType new("Class", token)
        instanceType = BaseType new(name, token)
        instanceType as BaseType ref = this
        thisDecl    = VariableDecl new(instanceType, "this", token)
        thisRefDecl = VariableDecl new(ReferenceType new(instanceType, token), "this", token)
        
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
    
    init: func ~typeDecl (.name, .superType, .token) {
        init(name, token)
        setSuperType(superType)
    }

    getFullName: func -> String {
        underName()
    }
    
    setSuperType: func(=superType) {
        if(!this isMeta && superType != null) {
            // TODO: there's probably a better way, but this works fine =)
            if(superType getName() == "Object" && name != "Class") {
                meta setSuperType(BaseType new("ClassClass", nullToken))
            } else {
                meta setSuperType(BaseType new(superType getName() + "Class", nullToken))
            }
        }
    }
    
    getSuperType: func -> Type { superType }
    
    addTypeArg: func (typeArg: VariableDecl) -> Bool {
        typeArg setOwner(this)
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
        if(vDecl isStatic() && !isMeta) {
            meta addVariable(vDecl)
        } else {
            variables put(vDecl name, vDecl)
            vDecl setOwner(this)
        }
    }
    
    addInterface: func (interfaceType: Type) {
        interfaceTypes add(interfaceType)
    }
    
    getInterfaceTypes: func -> List<Type>          { interfaceTypes }
    getInterfaceDecls: func -> List<InterfaceImpl> { interfaceDecls }

	hashName: func (name, suffix: String) -> String {
		suffix ? "%s~%s" format(name, suffix) : name
	}

	hashName: func ~fromFuncDecl (fDecl: FunctionDecl) -> String {
		hashName(fDecl getName(), fDecl getSuffix())
	}
    
    addFunction: func (fDecl: FunctionDecl) {
        if(isMeta) {
            functions put(hashName(fDecl), fDecl)
            fDecl setOwner(getNonMeta())
        } else {
            meta addFunction(fDecl)
        }
    }

	removeFunction: func(fDecl: FunctionDecl) {
		functions remove(hashName(fDecl))
	}
    
    lookupFunction: func (fName, fSuffix: String) -> FunctionDecl {
    
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
        return null
    }
    
    getVariables: func -> HashMap<String, VariableDecl> { variables }
    getFunctions: func -> HashMap<String, VariableDecl> { functions }
    
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
        if(module != null && !module underName isEmpty() && !isExtern()) {
            return module underName + "__" + name
        }
	return name       
    }
    
	getTypeArgs: func -> List<VariableDecl> { isMeta ? getNonMeta() typeArgs : typeArgs }

    getName: func -> String { name }
    
    setExternName: func (=externName) {}
    getExternName: func -> String {
        return (externName && !externName isEmpty()) ? externName : name
    }
    
    isExtern: func -> Bool { externName != null }
    
    getSuperRef: func -> TypeDecl {
        superType ? superType getRef() : null
    }
    
    getFunction: func ~call (call: FunctionCall, finalScore: Int@) -> FunctionDecl {
        return getFunction(call name, call suffix, call, finalScore&)
    }
    
    getFunction: func ~nameSuffCall (name, suffix: String, call: FunctionCall, finalScore: Int@) -> FunctionDecl {
        return getFunction(name, suffix, call, true, finalScore&)
    }
    
    getFunction: func ~nameSuffCallRec (name, suffix: String, call: FunctionCall, recursive: Bool, finalScore: Int@) -> FunctionDecl {
        return getFunction(name, suffix, call, recursive, 0, null, finalScore&)
    }
    
    getFunction: func ~real (name, suffix: String, call: FunctionCall,
        recursive: Bool, bestScore: Int, bestMatch: FunctionDecl, finalScore: Int@) -> FunctionDecl {

        for(fDecl: FunctionDecl in functions) {
            if(fDecl name equals(name) && (suffix == null || (suffix == "" && fDecl suffix == null) || fDecl suffix equals(suffix))) {
                if(!call) return fDecl
                score := call getScore(fDecl)
                if(call debugCondition()) "Considering fDecl %s for fCall %s, score = %d\n" format(fDecl toString(), call toString(), score) println()
                if(score == -1) {
                    finalScore = -1
                    return null // special score that means "something isn't resolved"
                }

                if(score > bestScore) {
                    bestScore = score
                    bestMatch = fDecl
                }
            }
        }
        
        if(call && call expr && call expr getType() && call expr getType() getRef() &&
           call expr getType() getRef() instanceOf(ClassDecl) &&
           call expr getType() getRef() as ClassDecl isMeta) {
            for(_fDecl: FunctionDecl in functions) {
                if(_fDecl isStatic()) continue
                fDecl := _fDecl getStaticVariant()
                if(!fDecl) continue
                if(fDecl name equals(name) && (suffix == null || (suffix == "" && fDecl suffix == null) || fDecl suffix equals(suffix))) {
                    if(!call) return fDecl
                    score := call getScore(fDecl)
                    if(score == -1) return null // special score that means "something isn't resolved"

                    if(score > bestScore) {
                        bestScore = score
                        bestMatch = fDecl
                    }
                }
            }
        }
        
        if(recursive && getSuperRef() != null) {
            return getSuperRef() getFunction(name, suffix, call, true, bestScore, bestMatch, finalScore&)
        }
        finalScore = bestScore
        return bestMatch
        
    }

    getModule: func -> Module { module }
    getType: func -> Type { type }
    getInstanceType: func -> Type { instanceType }
    getThisDecl: func -> VariableDecl { thisDecl }

    isResolved: func -> Bool { false }
    
    ghostTypeParams: func (trail: Trail, res: Resolver) -> Response {

        if(_finishedGhosting) return Responses OK
        
        // remove ghost type arguments
        if(this superType && !isMeta && !getTypeArgs() isEmpty()) {
            sType := this superType
            while(sType != null) {
                response := sType resolve(trail, res)
                if(!response ok()) {
                    return response
                }
                
                sTypeRef := sType getRef() as TypeDecl
                if(sTypeRef == null) {
                    res wholeAgain(this, "Need super type ref of " + sType toString())
                    return Responses OK
                }
                
                if(!sTypeRef getTypeArgs() isEmpty()) {
                    for(typeArg in getTypeArgs()) {
                        for(candidate in sTypeRef getTypeArgs()) {
                            if(typeArg getName() == candidate getName()) {
                                variables remove(typeArg getName())
                            }
                        }
                    }
                }
                sType = sTypeRef superType
            }
        }
        
        _finishedGhosting = true
        return Responses OK
        
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        
        //if(res params veryVerbose) printf("====== Resolving type decl %s\n", toString())
        
        {
            response := type resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        if(this superType) {
            response := this superType resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        if(!_finishedGhosting) {
            response := ghostTypeParams(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        for(typeArg in getTypeArgs()) {
            response := typeArg resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("Response of typeArg %s = %s\n", typeArg toString(), response toString())
                trail pop(this)
                return response
            }
        }

        for(vDecl in variables) {
            response := vDecl resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("Response of vDecl %s = %s\n", vDecl toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        for(fDecl in functions) {
            response := fDecl resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("Response of fDecl %s = %s\n", fDecl toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        if(meta) {
            meta module = module
            response := meta resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("-- %s, meta of %s, isn't resolved, looping.\n", meta toString(), toString())
                trail pop(this)
                return response
            }
        }
        
        i := 0
        for(interfaceType in interfaceTypes) {
            response := interfaceType resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("-- %s, interfaceType of %s, isn't resolved, looping.\n", interfaceType toString(), toString())
                trail pop(this)
                return response
            }
            if(interfaceType getRef() == null) {
                res wholeAgain(this, "Should resolve interface type %s first." format(interfaceType toString()))
                break
            } else if(i >= interfaceDecls size()) {
                iName := getName() + "__impl__" + interfaceType getName()
                interfaceDecl := InterfaceImpl new(iName, interfaceType, this, token)
                interfaceDecls add(interfaceDecl)
            }
            i += 1
        }
        
        for(interfaceDecl in interfaceDecls) {
            response := interfaceDecl resolve(trail, res)
            if(response ok()) {
                response = interfaceDecl getMeta() resolve(trail, res)
            }
            if(!response ok()) {
                if(res params veryVerbose) printf("-- %s, interfaceDecl, isn't resolved, looping.\n", interfaceDecl toString(), toString())
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
        
        // don't allow to resolve any access before finishing ghosting
        if(!_finishedGhosting) {
            return;
        }
        
        if(access getName() == "this") {
            if(access suggest(getNonMeta() ? getNonMeta() thisDecl : thisDecl)) return
        }
        
        if(access getName() == "This") {
            //printf("Asking for 'This' in %s (non-meta %s)\n", toString(), getNonMeta() ? getNonMeta() toString() : "(nil)")
            if(access suggest(getNonMeta() ? getNonMeta() : this)) return
        }
        
        vDecl := variables get(access getName())
        if(vDecl) {
            //"&&&&&&&& Found vDecl %s for %s in %s" format(vDecl toString(), access name, name) println()
            if(access suggest(vDecl)) {
            	if(access expr == null) {
	                varAcc := VariableAccess new("this", nullToken)
	                access expr = varAcc
                }
                return
            }
        }

        finalScore: Int
		fDecl := getFunction(access name, null, null, finalScore&)
        if(finalScore == -1) {
            return // something's not resolved
        }
		if(fDecl) {
            //"&&&&&&&& Found fDecl %s for %s" format(fDecl toString(), access name) println()
            if(access suggest(fDecl)) {
            	return
            }
		}
		
        if(getSuperRef() != null) {
        	//FIXME: should return here if success
            getSuperRef() resolveAccess(access)
        }
        
    }
    
    resolveCall: func (call : FunctionCall) {

        if(call debugCondition()) {
            printf("\n====> Search %s in %s\n", call toString(), name)
            for(f in functions) {
                printf("  - Got %s!\n", f toString())
            }
        }
        
        finalScore: Int
        fDecl := getFunction(call, finalScore&)
        if(finalScore == -1) {
            return // something's not resolved
        }
        if(fDecl) {
            if(call debugCondition()) "    \\o/ Found fDecl for %s, it's %s" format(call name, fDecl toString()) println()
            if(call suggest(fDecl)) {
	            if(call getExpr() == null) {
	            	call setExpr(VariableAccess new("this", call token))
            	}
            	if(call debugCondition()) "   returning..." println()
	            return
            }
        } else if(getSuperRef() != null) {
            if(call debugCondition()) printf("  <== going in superRef %s\n", getSuperRef() toString())
            getSuperRef() resolveCall(call)
        }
        
        if(call getRef() == null) {
            vDecl := getVariable(call getName())
            if(vDecl != null) {
                // FIXME this is far from good.
                if(vDecl getType() instanceOf(FuncType)) {
                    if(call suggest(vDecl getFunctionDecl())) {
                        if(call getExpr() == null) {
                            call setExpr(VariableAccess new("this", call token))
                        }
                    }
                }
            }
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
        repr := class name + ' ' + name
        if(getTypeArgs() isEmpty()) return repr
        b := Buffer new()
        b append(repr). append('<')
        isFirst := true
        for(typeArg in getTypeArgs()) {
            if(isFirst) isFirst = false
            else        b append(", ")
            b append(typeArg getName())
        }
        b append('>')
        return b toString()
    }
    
    getMeta: func -> ClassDecl { meta }
    getNonMeta: func -> This { nonMeta }
    
    setVersion: func (=verzion) {}
    getVersion: func -> VersionSpec { verzion ? verzion : (getNonMeta() ? getNonMeta() getVersion() : null) }

}

BuiltinType: class extends TypeDecl {
    
    init: func ~builtinType (.name, .token) {
        super(name, null, token)
    }
    
    underName: func -> String { name }
    
    accept: func (v: Visitor) { /* yeah, right. */ }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
}

