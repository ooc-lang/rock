import structs/[ArrayList, HashMap]
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
    
    addTypeArgument: func (typeArg: VariableDecl) -> Bool {
        typeArg owner = this
        typeArgs add(typeArg)
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
    
    addFunction: func (fDecl: FunctionDecl) {
        if(isMeta) {
            functions put(fDecl name, fDecl)
        } else {
            meta addFunction(fDecl)
        }
        fDecl owner = this
    }

	removeFunction: func(fDecl: FunctionDecl) {
		functions remove(fDecl getName())
	}
    
    getFunction: func (fName, fSuffix: String) -> FunctionDecl {
        // TODO add suffix handling
        fDecl : FunctionDecl = null
        fDecl = functions get(fName)
        return fDecl
    }
    
    getVariable: func (vName: String) -> VariableDecl {
        result := variables get(vName)
        if(result) return result
        
        if(isMeta) {
            return getNonMeta() getVariable(vName)
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
    
	getTypeArgs: func -> ArrayList<VariableDecl> { typeArgs }

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
        
        for(typeArg in typeArgs) {
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
        
        //printf("? Looking for variable %s in %s\n", access name, name)
        if(access getName() == "This") {
            if(access suggest(getNonMeta() ? getNonMeta() : this)) return
        }
        
        vDecl : VariableDecl = null
        vDecl = variables get(access name)
        if(vDecl) {
            //"&&&&&&&& Found vDecl for %s" format(access name) println()
            if(access suggest(vDecl) && access expr == null) {
                varAcc := VariableAccess new("this", nullToken)
                varAcc suggest(thisDecl)
                access expr = varAcc
                return
            }
        } else if(getSuperRef() != null) {
            getSuperRef() resolveAccess(access)
        }
        
        // look in type arguments
        for(typeArg in typeArgs) {
            if(access name == typeArg name) {
                if(access suggest(typeArg) && access expr == null) {
                    varAcc := VariableAccess new("this", nullToken)
                    varAcc suggest(thisDecl)
                    access expr = varAcc
                    return
                }
            }
        }
        
    }
    
    resolveCall: func (call : FunctionCall) {
        
        //printf("\n====> Search %s in %s\n", call toString(), name)
        /*
        for(f in functions) {
            printf("  - Got %s!\n", f toString())
        }
        */
        
        fDecl : FunctionDecl = null
        fDecl = functions get(call name)
        if(fDecl) {
            //"    \\o/ Found fDecl for %s\n" format(call name) println()
            accepted := call suggest(fDecl)
            if(accepted && call getExpr() == null) {
                call setExpr(VariableAccess new("this", call token))
            }
        } else if(getSuperRef() != null) {
            //printf("  <== going in superRef %s\n", superRef() toString())
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

