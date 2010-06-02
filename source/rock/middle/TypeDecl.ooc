import structs/[ArrayList, List, HashMap]
import ../frontend/[Token, BuildParams]
import ../io/TabbedWriter
import text/Buffer
import Expression, Type, Visitor, Declaration, VariableDecl, ClassDecl,
    FunctionDecl, FunctionCall, Module, VariableAccess, Node,
    InterfaceImpl, Version, EnumDecl, BaseType, FuncType
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

    base: TypeDecl = null    
    addons := ArrayList<TypeDecl> new()
    
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
    
    debugCondition: func -> Bool {
        false
    }
    
    init: func ~typeDecl (.name, .superType, .token) {
        init(name, token)
        setSuperType(superType)
    }
    
    writeSize: abstract func (w: TabbedWriter, instance: Bool)

    getBase: func -> TypeDecl {
        return isMeta ? base : getMeta() base
    }

    getAddons: func -> ArrayList<TypeDecl> {
        return isMeta ? addons : getMeta() addons
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

	hashName: static func (name, suffix: String) -> String {
		suffix ? "%s~%s" format(name, suffix) : name
	}

	hashName: static func ~fromFuncDecl (fDecl: FunctionDecl) -> String {
		This hashName(fDecl getName(), fDecl getSuffix())
	}
    
    addFunction: func (fDecl: FunctionDecl) {
        if(isMeta) {
            functions put(This hashName(fDecl), fDecl)
            fDecl setOwner(getNonMeta())
        } else {
            meta addFunction(fDecl)
        }
    }

	removeFunction: func(fDecl: FunctionDecl) {
		functions remove(This hashName(fDecl))
	}
    
    lookupFunction: func (fName, fSuffix: String) -> FunctionDecl {
    
    	// quick lookup, if we're lucky (exact suffix or no suffix)
        fDecl : FunctionDecl = null
        fDecl = functions get(This hashName(fName, fSuffix))
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
    getFunctions: func -> HashMap<String, FunctionDecl> { functions }
    
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
        return getFunction(name, suffix, call, recursive, INT_MIN, null, finalScore&)
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
                // Not ignoring static methods is intended; we want static member access without explicit `This`.
                fDecl := _fDecl getStaticVariant()
                if(!fDecl) continue
                if(fDecl name equals(name) && (suffix == null || (suffix == "" && fDecl suffix == null) || fDecl suffix equals(suffix))) {
                    if(!call) return fDecl
                    score := call getScore(fDecl)
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
        }
        
        if(recursive && getSuperRef() != null) {
            return getSuperRef() getFunction(name, suffix, call, true, bestScore, bestMatch, finalScore&)
        }
        if(finalScore == -1) return null
        
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
        
        if(debugCondition() || res params veryVerbose) printf("====== Resolving type decl %s\n", toString())
        
        {
            response := type resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("====== Response of type of %s == %s\n", toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        if(this superType) {
            response := this superType resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("====== Response of superType of %s == %s\n", toString(), response toString())
                trail pop(this)
                return response
            }
            
            if(superType getRef() != null) {
                checkInheritanceLoop(res)
            }
        }
        
        if(!_finishedGhosting) {
            response := ghostTypeParams(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("====== Response of type-param ghosting of %s == %s\n", toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        for(typeArg in getTypeArgs()) {
            response := typeArg resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("====== Response of typeArg %s of %s == %s\n", typeArg toString(), toString(), response toString())
                trail pop(this)
                return response
            }
        }

        for(vDecl in variables) {
            response := vDecl resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("====== Response of vDecl %s of %s == %s\n", vDecl toString(), toString(), response toString())
                trail pop(this)
                return response
            }
        }
        
        for(fDecl in functions) {
            response := fDecl resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("====== Response of fDecl %s of %s == %s\n", fDecl toString(), toString(), response toString())
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
                
                // It's easier to handle interfaces this way: if we implement ReaderWriter,
                // an interface that implements both the Reader and Writer interfaces,
                // instead of generating intermediate methods, we say that 
                transitiveInterfaces := interfaceType getRef() as TypeDecl getInterfaceTypes()
                if(!transitiveInterfaces isEmpty()) {
                    for(candidate in transitiveInterfaces) {
                        has := false
                        for(champion in getInterfaceTypes()) {
                            printf("%s vs %s\n", champion toString(), candidate toString())
                            if(candidate equals(champion)) {
                                has = true; break
                            }
                        }
                        if(!has) {
                            interfaceTypes add(candidate)
                            printf("Got new interface %s in %s by interface-implementation transitivity.\n", candidate toString(), toString())
                            res wholeAgain(this, "Got new interface by interface-implementation transitivity.")
                        }
                    }
                }
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
    
    checkInheritanceLoop: func (res: Resolver) {
        
        list := ArrayList<TypeDecl> new()
        current := this
        
        while(current != null) {
            if(current getSuperType() == null) break // it's alright
            
            next := current getSuperRef()
            if(next == null) {
                res wholeAgain(this, "need superRef to check inheritance loop")
            }
            
            list add(current)
            if(list contains(next)) {
                buff := Buffer new()
                isFirst := true
                for(t in list) {
                    if(!isFirst) buff append(" -> ")
                    buff append(t getName())
                    isFirst = false
                }
                list first() token throwError("Loop in type declaration: %s -> %s -> ..." format(buff toString(), next getName(), list size()))
            }
            
            current = next
        }
        
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

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        
        if(access debugCondition()) {
            "Resolving access %s. isMeta = %s\n" format(access toString(), isMeta toString()) println()
        }
        
        // don't allow to resolve any access before finishing ghosting
        if(!_finishedGhosting) {
            return -1
        }
        
        if(access getName() == "this") {
            if(access suggest(getNonMeta() ? getNonMeta() thisDecl : thisDecl)) return 0
        }
        
        if(access getName() == "This") {
            //printf("Asking for 'This' in %s (non-meta %s)\n", toString(), getNonMeta() ? getNonMeta() toString() : "(nil)")
            if(access suggest(getNonMeta() ? getNonMeta() : this)) return 0
        }
        
        if(access debugCondition()) {
            for(v in variables) {
                printf("Got var %s.%s\n", toString(), v toString())
            }
            for(f in functions) {
                printf("Got function %s.%s\n", toString(), f toString())
            }
        }
        
        vDecl := variables get(access getName())
        if(vDecl) {
            //"&&&&&&&& Found vDecl %s for %s in %s" format(vDecl toString(), access name, name) println()
            if(access suggest(vDecl)) {
            	if(access expr == null) {
	                varAcc := VariableAccess new("this", nullToken)
	                access expr = varAcc
                }
                return 0
            }
        }

        finalScore: Int
		fDecl := getFunction(access name, null, null, finalScore&)
        if(finalScore == -1) {
            return -1 // something's not resolved
        }
		if(fDecl) {
            //"&&&&&&&& Found fDecl %s for %s" format(fDecl toString(), access name) println()
            if(access suggest(fDecl)) {
            	return 0
            }
		}
		
        if(getSuperRef() != null) {
        	//FIXME: should return here if success
            getSuperRef() resolveAccess(access, res, trail)
        }
        
        // ask the metaclass for the variable (makes static member access without explicit `This` possible)
        if(!isMeta) {
            mvDecl : Declaration
            
            mvDecl = getMeta() variables get(access getName())
            if(mvDecl == null) {
                mvDecl = getMeta() functions get(access getName())
            }
            
            if(mvDecl != null && access suggest(mvDecl)) {
            	if(access expr == null) {
                    varAcc := VariableAccess new(getInstanceType(), nullToken)
                    access expr = varAcc
                }
                return 0
            }
        }
        
        0
        
    }
    
    resolveCall: func (call : FunctionCall, res: Resolver, trail: Trail) -> Int {

        if(call debugCondition()) {
            printf("\n====> Search %s in %s (which has %d functions)\n", call toString(), name, functions size())
            for(f in functions) {
                printf("  - Got %s!\n", f toString())
            }
        }
        
        finalScore: Int
        fDecl := getFunction(call name, call suffix, call, true, finalScore&)
        if(finalScore == -1) {
            res wholeAgain(call, "Got -1 from finalScore!")
            return -1 // something's not resolved
        }
        if(fDecl) {
            if(call debugCondition()) "    \\o/ Found fDecl for %s, it's %s" format(call name, fDecl toString()) println()
            if(call suggest(fDecl)) {
	            if(call getExpr() == null) {
	            	call setExpr(VariableAccess new("this", call token))
            	}
            	if(call debugCondition()) "   returning..." println()
	            return 0
            }
        }/* else if(getSuperRef() != null) {
            if(call debugCondition()) printf("  <== going in superRef %s\n", getSuperRef() toString())
            if(getSuperRef() resolveCall(call, res, trail) == -1) return -1
        }*/ // FIXME: uncomment when we're sure this doesn't cause any problems
        
        if(getBase() != null) {
            if(call debugCondition()) printf("Looking in base %s\n", getBase() toString())
            if(getBase() resolveCall(call, res, trail) == -1) return -1
        }
       
        for(addon in getAddons()) {
            has := false
            // TODO: What about namespaced imports?
            for(imp in call token module getGlobalImports()) {
                if(imp getModule() == addon token module) {
                    //printf("has because of import %s which equals %s\n", imp getModule() getFullName(), addon token toString())
                    has = true
                    break
                }
            }
            
            // It's also possible that the addon was defined in the
            // function call's module.
            if(call token module == addon token module && call token module == token module) {
                //printf("has because call token module %s is the same as addon token module %s\n", call token toString(), addon token toString())
                has = true
            }
            
            if(!has) continue
            
            //if(call debugCondition()) printf("From %s (%s), looking into addon %s (%s)\n",
            //    toString(), token toString(), addon toString(), addon token toString())
            if(addon resolveCall(call, res, trail) == -1) return -1
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
        
        0
        
    }
    
    inheritsFrom: func (tDecl: TypeDecl) -> Bool {
        superRef := getSuperRef()
        if(superRef != null) {
        	if(superRef == tDecl) return true
	        return superRef inheritsFrom(tDecl)
        }
        
        return false
    }
    
    inheritsScore: func (tDecl: TypeDecl, scoreSeed: Int) -> Int {
        
        if(debugCondition()) printf("inheritsScore between %s and %s. scoreSeed = %d\n", toString(), tDecl toString(), scoreSeed)
        
        for(interfaceDecl in interfaceDecls) {
            if(interfaceTypes size() != interfaceDecls size()) return -1
            if(interfaceDecl == tDecl) return scoreSeed
            score := interfaceDecl inheritsScore(tDecl, scoreSeed / 2)
            if(score != Type NOLUCK_SCORE) return score
        }
        
        if(getSuperType() != null) {
            superRef := getSuperRef()
            if(debugCondition()) printf("superRef = %s\n", superRef toString())
            
            if(superRef == null) return -1            
            if(superRef == tDecl) return scoreSeed
            return superRef inheritsScore(tDecl, scoreSeed / 2)
        }
        
        return Type NOLUCK_SCORE
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
    
    writeSize: func (w: TabbedWriter, instance: Bool) { Exception new(This, "writeSize() called on a BuiltinType. wtf?") /* if this happens, we're screwed */ }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
}

