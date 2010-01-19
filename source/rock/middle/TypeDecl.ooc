import structs/HashMap
import ../frontend/Token
import Expression, Type, Visitor, Declaration, VariableDecl, ClassDecl,
    FunctionDecl, FunctionCall, Module, VariableAccess, Node
import tinker/[Resolver, Response, Trail]

TypeDecl: abstract class extends Declaration {

    name: String
    externName: String = null

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
    
    init: func ~typeDecl (=name, =superType, .token) {
        super(token)
        type = BaseType new("Class", token)
        instanceType = BaseType new(name, token)
        instanceType as BaseType ref = this
        thisDecl = VariableDecl new(instanceType, "this", nullToken)
        
        // determine super-class
        if(!this superType && !isObjectClass()) {
            // everyone inherits from object, darling.
            this superType = BaseType new("Object", token)
        }
        
        if(!this isMeta) {
            // create the meta-class
            metaSuperType : Type = null
            if(this superType) {
                metaSuperType = BaseType new(this superType getName() + "Class", nullToken)
            } else {
                metaSuperType = BaseType new("Class", nullToken)
            }
            meta = ClassDecl new(name + "Class", metaSuperType, true, token)
            meta nonMeta = this
            meta thisDecl = this thisDecl
            
            // if we access to "Dog", we access to an object of type "DogClass"
            type = meta getInstanceType()
            type as BaseType ref = meta
        }
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
        if(!isMeta) {
            meta addFunction(fDecl)
        } else {
            functions put(fDecl name, fDecl)
        }
        fDecl owner = this
    }
    
    getFunction: func (fName, fSuffix: String) -> FunctionDecl {
        // TODO add suffix handling
        fDecl : FunctionDecl = null
        fDecl = functions get(fName)
        return fDecl
    }
    
    getVariable: func (vName: String) -> VariableDecl {
        variables get(vName)
    }
    
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
    
    getName: func -> String { name }
    
    getExternName: func -> String {
        return (externName && !externName isEmpty()) ? externName : name
    }
    
    isExtern: func -> Bool { externName != null }
    
    superRef: func -> TypeDecl {
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
        
        if(recursive && superRef()) {
            return superRef() getFunction(name, suffix, call, true, bestScore, bestMatch)
        }
        return bestMatch
        
    }
    
    getType: func -> Type { type }
    getInstanceType: func -> Type { instanceType }

    isResolved: func -> Bool { false }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        
        //printf("====== Resolving type decl %s\n", toString())
        
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
        
        for(vDecl in variables) {
            response := vDecl resolve(trail, res)
            //printf("Response of vDecl %s = %s\n", vDecl toString(), response toString())
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        for(fDecl in functions) {
            response := fDecl resolve(trail, res)
            //printf("Response of fDecl %s = %s\n", fDecl toString(), response toString())
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        if(meta) {
            meta module = module
            response := meta resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                //printf("-- %s, meta of %s, isn't resolved, looping.\n", meta toString(), toString())
                return response
            }
        }
        
        trail pop(this)
        
        return Responses OK
        
    }
    
    resolveAccess: func (access: VariableAccess) {
        
        //printf("? Looking for variable %s in %s\n", access name, name)
        
        vDecl : VariableDecl = null
        vDecl = variables get(access name)
        if(vDecl) {
            //"&&&&&&&& Found vDecl for %s" format(access name) println()
            if(access suggest(vDecl) && access expr == null) {
                varAcc := VariableAccess new("this", nullToken)
                varAcc suggest(thisDecl)
                access expr = varAcc
            }
        } else if(superRef()) {
            superRef() resolveAccess(access)
        }
    }
    
    resolveCall: func (call : FunctionCall) {
        
        //printf("\n? Looking for function %s in %s\n", call name, name)
        
        fDecl : FunctionDecl = null
        fDecl = functions get(call name)
        if(fDecl) {
            //"&&&&&&&& Found fDecl for %s\n" format(call name) println()
            call suggest(fDecl)
        } else if(superRef()) {
            //printf("Looking for call in superRef %s\n", superRef() toString())
            superRef() resolveCall(call)
        }
        
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

