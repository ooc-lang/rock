import structs/[ArrayList, List, HashMap]
import ../frontend/[Token, BuildParams]
import ../io/TabbedWriter
import Expression, Type, Visitor, Declaration, VariableDecl, ClassDecl,
    FunctionDecl, FunctionCall, Module, VariableAccess, Node,
    InterfaceImpl, Version, EnumDecl, BaseType, FuncType, OperatorDecl,
    Addon, Cast
import tinker/[Resolver, Response, Trail, Errors]

/**
   A type declaration - a class, a cover, an interface, an enum..

   A type declaration has a name, optionally an extern-name,
   optional generic type arguments, but also variables and functions.

   This is a base class containing many useful variables and methods, but
   the most interesting parts are in its subclasses ClassDecl, CoverDecl,
   InterfaceDecl, and EnumDecl.

   :author: Amos Wenger (nddrylliog)
 */
TypeDecl: abstract class extends Declaration {

    name = "", externName = null, doc = "" : String

    // generic type args, e.g. the T in List: class <T>
    typeArgs := ArrayList<VariableDecl> new()

    // internal state variables
    hasCheckedInheritance := false
    hasCheckedAbstract := false

    variables := HashMap<String, VariableDecl> new()

    // for classes, functions are contained in the meta-class.
    // for covers, they are directly in the cover decl.
    functions := HashMap<String, FunctionDecl> new()

    // interface types that this type implements
    interfaceTypes := ArrayList<Type> new()
    // InterfaceImpl is used for storing
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
    addons := ArrayList<Addon> new()

    _finishedGhosting := false

    // implicit conversions between types
    implicitConversions := ArrayList<OperatorDecl> new()

    init: func ~typeDeclNoSuper (=name, .token) {
        super(token)
        type = BaseType new("Class", token)
        instanceType = BaseType new(name, token)
        instanceType as BaseType ref = this
        thisDecl    = VariableDecl new(instanceType, "this", token)
        thisDecl owner = this
        thisRefDecl = VariableDecl new(ReferenceType new(instanceType, token), "this", token)
        thisRefDecl owner = this

        if(!isMeta) {
            meta = ClassDecl new(name + "Class", null, true, token)
            meta nonMeta = this
            meta thisDecl = this thisDecl
            meta setSuperType(BaseType new("Class", token))

            // if we access to "Dog", we access to an object of type "DogClass"
            type = meta getInstanceType()
            type as BaseType ref = meta
        }

        if(!isObjectClass()) {
            // by default, everyone inherits from object
            setSuperType(BaseType new("Object", token))
        }
    }

    clone: func -> This {
        // saving us a whole lot of trouble.
        Exception new(This, "Cloning a TypeDecl is unsupported") throw()
        null
    }

    debugCondition: inline func -> Bool {
        false
    }

    isAbstract: func -> Bool { false }

    init: func ~typeDecl (.name, .superType, .token) {
        init(name, token)
        setSuperType(superType)
    }

    writeSize: abstract func (w: TabbedWriter, instance: Bool)

    getBase: func -> TypeDecl {
        return isMeta ? base : getMeta() base
    }

    isAddon: func -> Bool { getBase() != null }

    getAddons: func -> ArrayList<Addon> {
        return isMeta ? getNonMeta() addons : addons
    }

    getFullName: func -> String {
        underName()
    }

    setSuperType: func(=superType) {
        if(!this isMeta && superType != null) {
            // TODO: there's probably a better way, but this works fine =)
            if(superType getName() == "Object" && name != "Class") {
                meta setSuperType(BaseType new("ClassClass", superType token))
            } else {
                meta setSuperType(BaseType new(superType getName() + "Class", superType token))
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
        name equals?("Object") || name equals?("ObjectClass")
    }

    isClassClass: func -> Bool {
        name equals?("Class") || name equals?("ClassClass")
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
        suffix ? "%s~%s" format(name toCString(), suffix toCString()) : name
    }

    hashName: static func ~fromFuncDecl (fDecl: FunctionDecl) -> String {
        This hashName(fDecl getName(), fDecl getSuffix())
    }

    addFunction: func (fDecl: FunctionDecl) {
        if(isMeta) {
            hash := hashName(fDecl)
            old := functions get(hash)
            if (old != null && fDecl getName() != "init") { /* init is an exception */
                if(old == fDecl) Exception new(This, "Replacing %s with %s, which is the same!" format (old getName() toCString(), fDecl getName() toCString())) throw()
                token module params errorHandler onError(FunctionRedefinition new(old, fDecl))
                return
            }

            functions put(hash, fDecl)
            fDecl setOwner(getNonMeta())
        } else {
            meta addFunction(fDecl)
        }
    }

    removeFunction: func(fDecl: FunctionDecl) {
        if(isMeta) {
            functions remove(This hashName(fDecl))
        } else {
            meta removeFunction(fDecl)
        }
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
        if(module != null && !module underName empty?() && !isExtern()) {
            return module underName + "__" + name
        }
        return name
    }

    getTypeArgs: func -> List<VariableDecl> { isMeta ? getNonMeta() typeArgs : typeArgs }

    getName: func -> String { name }

    setExternName: func (=externName) {}
    getExternName: func -> String {
        return (externName && !externName empty?()) ? externName : name
    }

    isExtern: func -> Bool { externName != null }

    getSuperRef: inline func -> TypeDecl {
        superType ? superType getRef() as TypeDecl : null
    }

    getFunction: func ~call (call: FunctionCall, finalScore: Int@) -> FunctionDecl {
        return getFunction(call name, call suffix, call, finalScore&)
    }

    getFunction: func ~name (name: String, finalScore: Int@) -> FunctionDecl {
        return getFunction(name, null, null, true, finalScore&)
    }

    getFunction: func ~nameSuff (name, suffix: String, finalScore: Int@) -> FunctionDecl {
        return getFunction(name, suffix, null, true, finalScore&)
    }

    getFunction: func ~nameCall (name: String, call: FunctionCall, finalScore: Int@) -> FunctionDecl {
        return getFunction(name, null, call, true, finalScore&)
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
            if(fDecl name == name && (suffix == null || (suffix == "" && fDecl suffix == null) || fDecl suffix == suffix)) {
                if(!call) return fDecl
                score := call getScore(fDecl)
                if(call debugCondition()) "Considering fDecl %s for fCall %s, score = %d\n" format(fDecl toString() toCString(), call toString() toCString(), score) println()
                if(score == -1) {
                    finalScore = -1 // special score that means "something isn't resolved"
                    return null
                }

                if(score > bestScore) {
                    bestScore = score
                    bestMatch = fDecl
                }
            }
        }

        if(call && call expr && call expr getType() && call expr getType() getRef() &&
           call expr getType() getRef() instanceOf?(ClassDecl) &&
           call expr getType() getRef() as ClassDecl isMeta) {
            for(fDecl: FunctionDecl in functions) {
                // Not ignoring static methods is intended; we want static member access without explicit `This`.
                if(fDecl name == name && (suffix == null || (suffix == "" && fDecl suffix == null) || fDecl suffix == suffix)) {
                    if(!fDecl isStatic) fDecl = fDecl getStaticVariant()

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

        if(_finishedGhosting) return Response OK

        // remove ghost type arguments
        if(this superType && !isMeta && !getTypeArgs() empty?()) {
            sType := this superType
            while(sType != null) {
                response := sType resolve(trail, res)
                if(!response ok()) {
                    return response
                }

                sTypeRef := sType getRef() as TypeDecl
                if(sTypeRef == null) {
                    res wholeAgain(this, "Need super type ref of " + sType toString())
                    return Response OK
                }

                if(!sTypeRef getTypeArgs() empty?()) {
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
        return Response OK

    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)

        if(debugCondition() || res params veryVerbose) printf("====== Resolving type decl %s\n", toString() toCString())

        if (!type isResolved()) {
            response := type resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) printf("====== Response of type of %s == %s\n", toString() toCString(), response toString() toCString())
                trail pop(this)
                return response
            }
        }

        if (superType) {
            if(!superType isResolved()) {
                response := superType resolve(trail, res)
                if(!response ok()) {
                    //if(debugCondition() || res params veryVerbose) printf("====== Response of superType of %s == %s\n", toString(), response toString())
                    trail pop(this)
                    return response
                }
            }

            //hasCheckedInheritance := static false
            if(!hasCheckedInheritance && superType getRef() != null) {
                if(checkInheritanceLoop(res)) hasCheckedInheritance = true
            }

            //hasCheckedAbstract := static false
            if(!hasCheckedAbstract && superType getRef() != null && isMeta) {
                if(checkAbstractFuncs(res)) hasCheckedAbstract = true
            }
        }

        if(!_finishedGhosting) {
            response := ghostTypeParams(trail, res)
            if(!response ok()) {
                //if(debugCondition() || res params veryVerbose) printf("====== Response of type-param ghosting of %s == %s\n", toString(), response toString())
                trail pop(this)
                return response
            }
        }

        i := 0
        for(interfaceType in interfaceTypes) {
            response := interfaceType resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("-- %s, interfaceType of %s, isn't resolved, looping.\n", interfaceType toString() toCString(), toString() toCString())
                trail pop(this)
                return response
            }
            if(interfaceType getRef() == null) {
                res wholeAgain(this, "Should resolve interface type first.")
                break
            } else if(i >= interfaceDecls getSize()) {
                iName := getName() + "__impl__" + interfaceType getName()
                interfaceDecl := InterfaceImpl new(iName, interfaceType, this, token)
                interfaceDecls add(interfaceDecl)

                // It's easier to handle interfaces this way: if we implement ReaderWriter,
                // an interface that implements both the Reader and Writer interfaces,
                // instead of generating intermediate methods, we say that
                transitiveInterfaces := interfaceType getRef() as TypeDecl getInterfaceTypes()
                if(!transitiveInterfaces empty?()) {
                    for(candidate in transitiveInterfaces) {
                        has := false
                        for(champion in getInterfaceTypes()) {
                            printf("%s vs %s\n", champion toString() toCString(), candidate toString() toCString())
                            if(candidate equals?(champion)) {
                                has = true; break
                            }
                        }
                        if(!has) {
                            interfaceTypes add(candidate)
                            printf("Got new interface %s in %s by interface-implementation transitivity.\n", candidate toString() toCString(), toString() toCString())
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
                if(res params veryVerbose) printf("-- %s, interfaceDecl, isn't resolved, looping.\n", interfaceDecl toString() toCString(), toString() toCString())
                trail pop(this)
                return response
            }
        }

        for(typeArg in getTypeArgs()) {
            response := typeArg resolve(trail, res)
            if(!response ok()) {
                //if(debugCondition() || res params veryVerbose) printf("====== Response of typeArg %s of %s == %s\n", typeArg toString(), toString(), response toString())
                trail pop(this)
                return response
            }
        }

        for(vDecl in variables) {
            response := vDecl resolve(trail, res)
            if(!response ok()) {
                //if(debugCondition() || res params veryVerbose) printf("====== Response of vDecl %s of %s == %s\n", vDecl toString(), toString(), response toString())
                trail pop(this)
                return response
            }
        }

        for(fDecl in functions) {
            response := fDecl resolve(trail, res)
            if(!response ok()) {
                //if(debugCondition() || res params veryVerbose) printf("====== Response of fDecl %s of %s == %s\n", fDecl toString(), toString(), response toString())
                trail pop(this)
                return response
            }
        }

        if(meta) {
            meta module = module
            response := meta resolve(trail, res)
            if(!response ok()) {
                //if(res params veryVerbose) printf("-- %s, meta of %s, isn't resolved, looping.\n", meta toString(), toString())
                trail pop(this)
                return response
            }
        }

        trail pop(this)

        return Response OK

    }

    checkAbstractFuncs: func (res: Resolver) -> Bool {

        if(getNonMeta() isAbstract()) {
            return true // nothing to check!
        }

        current := this

        implemented := HashMap<String, FunctionDecl> new()
        contract    := ArrayList<FunctionDecl> new()

        while(current != null) {
            for(fDecl in current getFunctions()) {
                if(fDecl isAbstract) {
                    contract add(fDecl)
                } else {
                    hash := "%s_%s" format(fDecl getName() toCString(), fDecl getSuffix() ? fDecl getSuffix() toCString() : "" toCString())
                    implemented put(hash, fDecl)
                }
            }

            if(current getSuperType() != null && current getSuperRef() == null) {
                res wholeAgain(this, "Needs superRef to check abstract funcs")
                return false
            }
            current = current getSuperRef()
        }

        for(fDecl in contract) {
            hash := "%s_%s" format(fDecl getName() toCString(), fDecl getSuffix() ? fDecl getSuffix() toCString() : "" toCString())
            candidate := implemented get(hash)
            if(candidate == null) {
                if(fDecl getOwner() == getNonMeta() || fDecl getOwner() == this) {
                    res throwError(AbstractContractNotSatisfied new(token,
                        "`%s` should be declared abstract, because it defines abstract function `%s%s%s`" format(
                        getNonMeta() getName() toCString(),
                        fDecl getSuffix() ? (fDecl getName() + "~" + fDecl getSuffix()) toCString() : fDecl getName() toCString(),
                        fDecl args empty?() ? "" toCString() : (" " + fDecl getArgsRepr()) toCString(),
                        fDecl hasReturn() ? (" -> " + fDecl returnType toString()) toCString() : "" toCString()
                    )))
                } else {
                    res throwError(AbstractContractNotSatisfied new(
                        token,"`%s` must implement function `%s%s%s` because it extends `%s`" format(
                        getNonMeta() getName() toCString(),
                        fDecl getSuffix() ? (fDecl getName() + "~" + fDecl getSuffix()) toCString() : fDecl getName() toCString(),
                        fDecl args empty?() ? "" toCString() : (" " + fDecl getArgsRepr()) toCString(),
                        fDecl hasReturn() ? (" -> " + fDecl returnType toString()) toCString() : "" toCString(),
                        fDecl getOwner() getName() toCString()
                    )))
                }
            }
        }

        return true

    }

    checkInheritanceLoop: func (res: Resolver) -> Bool {

        list := ArrayList<TypeDecl> new()
        current := this

        while(current != null) {
            if(current getSuperType() == null) break // it's alright

            next := current getSuperRef()
            if(next == null) {
                res wholeAgain(this, "need superRef to check inheritance loop")
                return false
            }

            list add(current)
            if(list contains?(next)) {
                buff := Buffer new()
                isFirst := true
                for(t in list) {
                    if(!isFirst) buff append(" -> ")
                    buff append(t getName())
                    isFirst = false
                }
                res throwError(InheritanceLoop new(list first() token, "Loop in type declaration: %s -> %s -> ..." format(buff toString() toCString(), next getName() toCString(), list getSize())))
            }

            current = next
        }
        true

    }

    resolveType: func (type: BaseType, res: Resolver, trail: Trail) -> Int {
        if(type getName() == "This") {
            if(type suggest(getNonMeta() ? getNonMeta() : this)) return 0
        }

        for(typeArg: VariableDecl in getTypeArgs()) {
            if(typeArg name == type name) {
                type suggest(typeArg)
                return 0
            }
        }

        0
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {

        if(access debugCondition()) {
            "Resolving access %s. isMeta = %s\n" format(access toString() toCString(), isMeta toString() toCString()) println()
        }

        // don't allow to resolve any access before finishing ghosting
        if(!_finishedGhosting) {
            return -1
        }

        if(access getName() == "This") {
            //printf("Asking for 'This' in %s (non-meta %s)\n", toString(), getNonMeta() ? getNonMeta() toString() : "(nil)")
            if(access suggest(getNonMeta() ? getNonMeta() : this)) return 0
        }

        if(access debugCondition()) {
            for(v in variables) {
                printf("Got var %s %s\n", toString() toCString(), v toString() toCString())
            }
            for(f in functions) {
                printf("Got function %s %s\n", toString() toCString(), f toString() toCString())
            }
        }

        vDecl := variables get(access getName())
        if(vDecl) {
            //"&&&&&&&& Found vDecl %s for %s in %s" printfln(vDecl toString() toCString(), access name toCString(), name toCString())
            if(access suggest(vDecl)) {
                if(access expr == null) {
                    varAcc := VariableAccess new("this", access token)
                    varAcc reverseExpr = access
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

        for(interfaceType in interfaceTypes) {
            iRef := interfaceType getRef()
            if(iRef) {
                if(name == "T") {
                    "Trying to resolve T in interface type %s, ref %s" format(interfaceType toString() toCString(), iRef toString() toCString()) println()
                }
                iRef resolveAccess(access, res, trail)
            }
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
            printf("\n====> Search %s in %s (which has %d functions)\n", call toString() toCString(), name toCString(), functions getSize())
            for(f in functions) {
                printf("  - Got %s!\n", f toString() toCString())
            }
        }

        finalScore: Int
        fDecl := getFunction(call name, call suffix, call, true, finalScore&)
        if(finalScore == -1) {
            if(res fatal) {
                // if fatal and because of us, resolve ourselves to get a meaningful error message
                // instead of getting a cryptic error on the call-side (like, 'No such function blah'
                // where clearly such a function exists)
                resolve(Trail new(token module), res)
            }
            return -1 // something's not resolved
        }
        if(fDecl) {
            if(call debugCondition()) "    \\o/ Found fDecl for %s, it's %s" format(call name toCString(), fDecl toString() toCString()) println()
            if(call suggest(fDecl, res, trail)) {
                if(fDecl hasThis() && !call getExpr()) {
                    call setExpr(VariableAccess new("this", call token))
                }
                return 0
            }
        }

        for(addon in getAddons()) {
            has := false

            // It's also possible that the addon was defined in the
            // function call's module.
            if(call token module == addon token module) {
                has = true
            } else for(imp in call token module getGlobalImports()) {
                if(imp getModule() == addon token module) {
                    has = true
                    break
                }
            }

            if(!has) {
                continue
            }

            if(addon resolveCall(call, res, trail) == -1) return -1
        }

        if(call getRef() == null) {
            vDecl := getVariable(call getName())
            if(vDecl != null) {
                // FIXME this is far from good.
                if(vDecl getType() instanceOf?(FuncType)) {
                    if(call suggest(vDecl getFunctionDecl(), res, trail)) {
                        if(call getExpr() == null) {
                            call setExpr(VariableAccess new("this", call token))
                        }
                    }
                }
            }
        }

        0

    }

    inheritsFrom?: func (tDecl: TypeDecl) -> Bool {
        superRef := getSuperRef()
        if(superRef != null) {
            if(superRef == tDecl) return true
            return superRef inheritsFrom?(tDecl)
        }

        return false
    }

    inheritsScore: func (tDecl: TypeDecl, scoreSeed: Int) -> Int {

        if(debugCondition()) printf("inheritsScore between %s and %s. scoreSeed = %d\n", toString() toCString(), tDecl toString() toCString(), scoreSeed)

        for(interfaceDecl in interfaceDecls) {
            if(interfaceTypes getSize() != interfaceDecls getSize()) return -1
            if(interfaceDecl == tDecl) return scoreSeed
            score := interfaceDecl inheritsScore(tDecl, scoreSeed / 2)
            if(score != Type NOLUCK_SCORE) return score
        }

        if(getSuperType() != null) {
            superRef := getSuperRef()
            if(debugCondition()) printf("superRef = %s\n", superRef toString() toCString())

            if(superRef == null) return -1
            if(superRef == tDecl) return scoreSeed
            return superRef inheritsScore(tDecl, scoreSeed / 2)
        }

        return Type NOLUCK_SCORE
    }

    toString: func -> String {
        repr := class name + ' ' + name
        if(getTypeArgs() empty?()) return repr
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

    clone: func -> This {
        // what's the use in copying a BuiltinType? it's not like anything can change anyway
        this
    }

    underName: func -> String { name }

    accept: func (v: Visitor) { /* yeah, right. */ }

    writeSize: func (w: TabbedWriter, instance: Bool) { Exception new(This, "writeSize() called on a BuiltinType. wtf?") throw() /* if this happens, we're screwed */ }

    replace: func (oldie, kiddo: Node) -> Bool { false }

}

TypeRedefinition: class extends Error {

    first, second: TypeDecl

    init: func (=first, =second) {
        message = second token formatMessage("Redefinition of '%s'%s" format(first getName() toCString(), first verzion ? (" in version " + first verzion toString()) toCString() : "" toCString()), "[INFO]") + '\n' +
                  first  token formatMessage("\n...first definition was here: ", "[ERROR]")
    }

    format: func -> String {
        message
    }

}

AbstractContractNotSatisfied: class extends Error {
    init: super func ~tokenMessage
}

InheritanceLoop: class extends Error {
    init: super func ~tokenMessage
}
