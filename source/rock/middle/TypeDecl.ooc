import structs/[ArrayList, List, HashMap, MultiMap]
import ../frontend/[Token, BuildParams]
import ../io/TabbedWriter
import Expression, Type, Visitor, Declaration, VariableDecl, ClassDecl,
    FunctionDecl, FunctionCall, Module, VariableAccess, Node,
    InterfaceImpl, Version, EnumDecl, BaseType, FuncType, OperatorDecl,
    Addon, Cast, PropertyDecl, CoverDecl
import tinker/[Resolver, Response, Trail, Errors]

/**
 * A type declaration - a class, a cover, an interface, an enum..
 *
 * A type declaration has a name, optionally an extern-name,
 * optional generic type arguments, but also variables and functions.
 *
 * This is a base class containing many useful variables and methods, but
 * the most interesting parts are in its subclasses ClassDecl, CoverDecl,
 * InterfaceDecl, and EnumDecl.
 */
TypeDecl: abstract class extends Declaration {

    name = "", externName = null, doc = "" : String

    prettyName: String { get {
      unbangify(name)
    } }

    // generic type args, e.g. the T in List: class <T>
    typeArgs := ArrayList<VariableDecl> new()

    // type arg instances - this is used for cover templates,
    // when instanciating for example Array: cover template <T> to
    // Array<Int>, we have "T" => BaseType("Int") and we can
    // directly suggest the Int type instead of T
    templateArgs := HashMap<String, Declaration> new()

    // internal state variables
    hasCheckedInheritance := false
    hasCheckedAbstract := false
    hasCheckedRedefine := false

    // the crux of the matter
    variables := HashMap<String, VariableDecl> new()
    functions := MultiMap<String, FunctionDecl> new()
    operators := ArrayList<OperatorDecl> new()

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

    isPrimitiveType: func -> Bool {
        false
    }

    clone: func -> This {
        // saving us a whole lot of trouble.
        Exception new(This, "Cloning a TypeDecl is unsupported") throw()
        null
    }

    debugCondition: final func -> Bool {
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
                namespace := (superType instanceOf?(BaseType)) ? superType as BaseType namespace : null
                meta setSuperType(BaseType new(superType getName() + "Class", namespace, superType token))
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
        old := getVariable(vDecl name)

        if(!old || old == vDecl) {
            if(vDecl isStatic() && !isMeta) {
                meta addVariable(vDecl)
            } else {
                variables put(vDecl name, vDecl)
                vDecl setOwner(this)
            }
        } else {
            token module params errorHandler onError(DuplicateField new(vDecl, old))
        }
    }

    addInterface: func (interfaceType: Type) {
        interfaceTypes add(interfaceType)
    }

    getInterfaceTypes: func -> List<Type>          { interfaceTypes }
    getInterfaceDecls: func -> List<InterfaceImpl> { interfaceDecls }

    hasMeta?: func -> Bool {
        !isMeta
    }

    addFunction: func (fDecl: FunctionDecl) {
        if (!isMeta)  {
            meta addFunction(fDecl)
            return
        }

        if (checkFunctionRedefinition(fDecl)) {
            // duplicate
            return
        }

        functions put(fDecl getName(), fDecl)
        fDecl setOwner(getNonMeta())
    }

    /**
     * Check if 'kiddo' is a redefinition of a previously
     * added method in this type.
     *
     * @return true if it is
     */
    checkFunctionRedefinition: func (kiddo: FunctionDecl) -> Bool {
        redefines := false

        functions getEachUntil(kiddo name, |oldie|
            if (oldie == kiddo) {
                // this is an internal error - it should never happen
                raise("in type #{name}, added #{oldie} more than once")
                redefines = true
            }

            if (kiddo getSuffixOrEmpty() == oldie getSuffixOrEmpty()) {
                // same suffixes, not okay
                err := FunctionRedefinition new(oldie, kiddo)
                token module params errorHandler onError(err)
                redefines = true
            }

            // as soon as we've found a redefinition, we can break
            !redefines
        )

        redefines
    }

    addOperator: func (oDecl: OperatorDecl) {
        operators add(oDecl)
        addFunction(oDecl fDecl)
    }

    removeFunction: func(fDecl: FunctionDecl) {
        if (!isMeta) {
            meta removeFunction(fDecl)
            return
        }

        functions removeValue(fDecl getName(), fDecl)
    }

    lookupFunction: func (fName: String, fSuffix: String = null) -> FunctionDecl {
        result: FunctionDecl

        functions getEachUntil(fName, |fDecl|
            if (fSuffix == null || fDecl getSuffixOrEmpty() == fSuffix) {
                result = fDecl
                // we've found, can break
                return false
            }

            // still looking for the right match, continue
            true
        )

        result
    }

    getVariableNonRecursive: func (vName: String) -> VariableDecl {
        variables get(vName)
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

        done := false
        result: FunctionDecl

        functions getEachUntil(name, |fDecl|
            if (suffix == null || (suffix == "" && fDecl suffix == null) || (fDecl suffix == suffix)) {
                if(!call) {
                    result = fDecl
                    done = true
                    return false // break
                }

                score := call getScore(fDecl)
                if(call debugCondition()) {
                    "Considering fDecl %s for fCall %s, score = %d\n" format(fDecl toString(), call toString(), score) println()
                }

                if(score > bestScore) {
                    bestScore = score
                    bestMatch = fDecl
                }
            }

            true
        )

        if (done) {
            return result
        }

        tempScore := 0

        if(call && call expr && call expr getType() && call expr getType() getRef() &&
           call expr getType() getRef() instanceOf?(ClassDecl) &&
           call expr getType() getRef() as ClassDecl isMeta) {

            functions getEachUntil(name, |fDecl|
                if (suffix == null || (suffix == "" && fDecl suffix == null) || (fDecl suffix == suffix)) {
                    // TODO: sounds expensive. Isn't it?
                    if(!fDecl isStatic) fDecl = fDecl getStaticVariant()

                    if (!call) {
                        result = fDecl
                        done = true
                        return false // break
                    }
                    score := call getScore(fDecl)
                    if(score == -1) {
                        tempScore = -1 // special score that means "something isn't resolved"
                        done = true
                        return false
                    }
                    if(score > bestScore) {
                        bestScore = score
                        bestMatch = fDecl
                    }
                }

                true
            )
        }

        if (done) {
            finalScore = tempScore
            return result
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

    checkFinalInherit: func(res: Resolver) -> Bool{
        list := ArrayList<TypeDecl> new()
        current := this

        while(current != null) {
            if(current getSuperType() == null) break // it's alright

            next := current getSuperRef()
            if(next == null) {
                res wholeAgain(this, "need superRef to check final redefine")
                return false
            }

            list add(current)
            current = next
        }

        if(list size > 2){
            for(i in 0..list size - 1){
                for(j in i+1..list size){
                    list[i] functions each(|fdecl|
                        if(fdecl name == "init" || fdecl name == "new"){ return }
                        list[j] functions getEachUntil(fdecl name, |other|
                            if (other isFinal && fdecl getSuffixOrEmpty() == other getSuffixOrEmpty()) {
                                res throwError(FinalInherit new(fdecl, other))
                                return true
                            }
                            false
                        )
                    )
                }
            }
        }
        true

    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)

        if(debugCondition() || res params veryVerbose) "====== Resolving type decl %s" printfln(toString())

        if (verzion && !verzion isResolved()) {
            verzion resolve(trail, res)
        }

        if (!type isResolved()) {
            response := type resolve(trail, res)
            if(!response ok()) {
                if(debugCondition() || res params veryVerbose) "====== Response of type of %s == %s" printfln(toString(), response toString())
                trail pop(this)
                return response
            }
        }

        if (superType) {
            if(!superType isResolved()) {
                response := superType resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    return response
                }
            }

            if(!hasCheckedInheritance && superType getRef() != null) {
                if(checkInheritanceLoop(res)) hasCheckedInheritance = true
            }

            if(!hasCheckedAbstract && superType getRef() != null && isMeta) {
                if(checkAbstractFuncs(res)) hasCheckedAbstract = true
            }

            if(getNonMeta() && getNonMeta() class == ClassDecl && !hasCheckedRedefine && superType getRef() != null){
                if(checkFinalInherit(res)) hasCheckedRedefine = true
            }

            // So we resolved the super type, we got to make sure we have no field redifinitions
            // We do want generic variable fields to be redefined though, so we ignore those
            // Also, properties can be redefined as the getter and setter are overloaded, which is fine
            if(superType getRef()) {
                variables each(|var|
                    if(!typeArgs contains?(var) && !var instanceOf?(PropertyDecl)) {
                        superVar := superType getRef() as TypeDecl getVariable(var name)
                        if(superVar && superVar != var) {
                            res throwError(DuplicateField new(var, superVar))
                        }
                    }
                )
            }
        }

        if(!_finishedGhosting) {
            response := ghostTypeParams(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        i := 0
        for(interfaceType in interfaceTypes) {
            response := interfaceType resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) "-- %s, interfaceType of %s, isn't resolved, looping." printfln(interfaceType toString(), toString())
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
                            "%s vs %s\n" printfln(champion toString(), candidate toString())
                            if(candidate equals?(champion)) {
                                has = true; break
                            }
                        }
                        if(!has) {
                            interfaceTypes add(candidate)
                            "Got new interface %s in %s by interface-implementation transitivity." printfln(candidate toString(), toString())
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
                if(res params veryVerbose) "-- %s, interfaceDecl, isn't resolved, looping." printfln(interfaceDecl toString(), toString())
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

        for(oDecl in operators) {
            response := oDecl resolve(trail, res)
            if(!response ok()) {
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
                    hash := "%s_%s" format(fDecl getName(), fDecl getSuffix() ? fDecl getSuffix() : "")
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
            hash := "%s_%s" format(fDecl getName(), fDecl getSuffix() ? fDecl getSuffix() : "")
            candidate := implemented get(hash)
            if(candidate == null) {
                if(fDecl getOwner() == getNonMeta() || fDecl getOwner() == this) {
                    res throwError(AbstractContractNotSatisfied new(token,
                        "`%s` should be declared abstract, because it defines abstract function `%s%s%s`" format(
                        getNonMeta() getName(),
                        fDecl getSuffix() ? (fDecl getName() + "~" + fDecl getSuffix()) : fDecl getName(),
                        fDecl args empty?() ? "" : (" " + fDecl getArgsRepr()),
                        fDecl hasReturn() ? (" -> " + fDecl returnType toString()) : ""
                    )))
                } else {
                    res throwError(AbstractContractNotSatisfied new(
                        token,"`%s` must implement function `%s%s%s` because it extends `%s`" format(
                        getNonMeta() getName(),
                        fDecl getSuffix() ? (fDecl getName() + "~" + fDecl getSuffix()) : fDecl getName(),
                        fDecl args empty?() ? "" : (" " + fDecl getArgsRepr()),
                        fDecl hasReturn() ? (" -> " + fDecl returnType toString()) : "",
                        fDecl getOwner() getName()
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
                res throwError(InheritanceLoop new(list first() token, "Loop in type declaration: %s -> %s -> ..." format(buff toString(), next getName(), list getSize())))
            }

            current = next
        }
        true

    }

    resolveType: func (type: BaseType, res: Resolver, trail: Trail) -> Int {

        if(type getName() == "This") {
            if(type suggest(getNonMeta() ? getNonMeta() : this)) return 0
        }

        {
            ref := templateArgs get(type name)
            if (ref) {
                if(type suggest(ref)) return 0
            }
        }

        for(typeArg in getTypeArgs()) {
            if(typeArg name == type name) {
                if(type suggest(typeArg)) return 0
            }
        }

        finalScore := 0
        haystack := getInstanceType()
        result := haystack searchTypeArg(type getName(), finalScore&)
        if (result && finalScore >= 0) {
            if(type suggest(result getRef())) return 0
        }

        0
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {

        if(access debugCondition()) {
            "resolveAccess(%s) in %s (%d vars, %d functions). isMeta = %s" printfln(access toString(), toString(), variables size, functions size, isMeta toString())
        }

        // don't allow to resolve any access before finishing ghosting
        if(!_finishedGhosting) {
            if (access debugCondition()) {
                "We haven't finished ghosting, abandon access resolution" println()
            }
            return -1
        }

        if(access getName() == "This") {
            //printf("Asking for 'This' in %s (non-meta %s)\n", toString(), getNonMeta() ? getNonMeta() toString() : "(nil)")
            if(access suggest(getNonMeta() ? getNonMeta() : this)) return 0
        }

        {
            ref := templateArgs get(access getName())
            if (ref) {
                if(access suggest(ref)) return 0
            }
        }

        if(access debugCondition()) {
            for(v in variables) {
                "Got var %s %s" printfln(toString(), v toString())
            }
            for(f in functions) {
                "Got function %s %s" printfln(toString(), f toString())
            }
        }

        vDecl := variables get(access getName())
        if(vDecl) {
            //"&&&&&&&& Found vDecl %s for %s in %s" printfln(vDecl toString(), access name, name)
            if(access suggest(vDecl)) {
                if(access expr == null) {
                    varAcc := VariableAccess new("this", access token)
                    varAcc reverseExpr = access
                    access expr = varAcc
                }
                return 0
            }
        }

        // Try to resolve access in addon properties
        for(addon in getAddons()) {
            if(resolveAccessInAddon(addon, access, res, trail) == -1) return -1
        }

        {
            ancestor := getSuperRef()
            while(ancestor != null) {
                for(addon in ancestor getAddons()) {
                    if(resolveAccessInAddon(addon, access, res, trail) == -1) return -1
                }
                ancestor = ancestor getSuperRef()
            }
        }

        if(access getRef()) {
            return 0
        }

        finalScore := 0
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
                    "Trying to resolve T in interface type %s, ref %s" format(interfaceType toString(), iRef toString()) println()
                }
                iRef resolveAccess(access, res, trail)
            }
        }

        // ask the metaclass for the variable (makes static
        // member access without explicit `This` possible)
        if(!isMeta) {
            mvDecl : Declaration

            // try variables first
            mvDecl = getMeta() variables get(access getName())
            if(mvDecl == null) {
                // or functions, that's good too.
                mvDecl = getMeta() lookupFunction(access getName())
            }

            if(mvDecl != null && access suggest(mvDecl)) {
                if(access expr == null) {
                    // Make a variable access '<Type> <name>'
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
            "\n====> Search %s in %s (which has %d functions)" printfln(call toString(), name, functions size)
            for(f in functions) {
                "  - Got %s!" printfln(f toString())
            }
        }

        finalScore := 0
        recursive := true
        if (call name == "new") {
            // constructors are special beasts :/
            recursive = false
        }

        fDecl := getFunction(call name, call suffix, call, recursive, finalScore&)
        if(finalScore == -1) {
            if(res fatal) {
                // if fatal and because of us, there could be two reasons
                // the first one is that we have invalid arguments (like the empty array lit), so we check that
                call checkArgumentValidity(res)

                // if the arguments are all valid, then it means that the error is somewhere in the definition
                // so we avoid throwing any error here, but rather let the definition throw something itself.
            }
        }
        if(fDecl) {
            if(call debugCondition()) "    \\o/ Found fDecl for %s, it's %s" format(call name, fDecl toString()) println()
            if(call suggest(fDecl, res, trail)) {
                if(fDecl hasThis() && !call getExpr()) {
                    call setExpr(VariableAccess new("this", call token))
                }
                return 0
            }
        }

        for(addon in getAddons()) {
            if(resolveCallInAddon(addon, call, res, trail) == -1) return -1
        }

        {
            ancestor := getSuperRef()
            while(ancestor != null) {
                for(addon in ancestor getAddons()) {
                    if(resolveCallInAddon(addon, call, res, trail) == -1) return -1
                }
                ancestor = ancestor getSuperRef()
            }
        }

        if(call getRef() == null) {
            vDecl := getVariable(call getName())
            if(vDecl != null) {
                // FIXME this is far from good.
                if(vDecl getType() instanceOf?(FuncType)) {
                    if(call suggest(vDecl getFunctionDecl(), res, trail)) {
                        if(call getExpr() == null) {
                            // if the variable is static, use class scope not instance
                            name := vDecl isStatic() ? "This" : "this"
                            call setExpr(VariableAccess new(name, call token))
                        }
                    }
                }
            }
        }

        0

    }

    resolveCallInAddon: func (addon: Addon, call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        has := false

        // It's also possible that the addon was defined in the
        // function call's module.
        if(call token module == addon token module) {
            has = true
        } else for(imp in call token module getAllImports()) {
            if(imp getModule() == addon token module) {
                has = true
                break
            }
        }

        if(has) {
            if(addon resolveCall(call, res, trail) == -1) return -1
        }

        0
    }

    resolveAccessInAddon: func (addon: Addon, access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        has := false

        // It's possible that the addon was defined in the accesses module
        if(access token module == addon token module) {
            has = true
        } else for(imp in access token module getGlobalImports()) {
            if(imp getModule() == addon token module) {
                has = true
                break
            }
        }

        if(has) {
            if(addon resolveAccess(access, res, trail) == -1) return -1
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

        if(debugCondition()) "inheritsScore between %s and %s. scoreSeed = %d" printfln(toString(), tDecl toString(), scoreSeed)

        for(interfaceDecl in interfaceDecls) {
            if(interfaceTypes getSize() != interfaceDecls getSize()) return -1
            if(interfaceDecl == tDecl) return scoreSeed
            score := interfaceDecl inheritsScore(tDecl, scoreSeed / 2)
            if(score != Type NOLUCK_SCORE) return score
        }

        if(getSuperType() != null) {
            superRef := getSuperRef()
            if(debugCondition()) "superRef = %s" printfln(superRef toString())

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

    setVersion: func (=verzion) {
        meat := getMeta()
        if(meat) meat setVersion(verzion) // let's hope there's no meta loop
    }
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
        super(second token, "Redefinition of '%s'%s" format(first getName(), first verzion ? (" in version " + first verzion toString()) : ""))
        next = InfoError new(first token, "...first definition was here:")
    }

}

DuplicateField: class extends Error {

    first, second: VariableDecl

    init: func(=first, =second) {
        super(second token, "Redefinition of '%s'" format(first getName()))
        next = InfoError new(first token, "...first definition was here:")
    }
}

AbstractContractNotSatisfied: class extends Error {
    init: super func ~tokenMessage
}

InheritanceLoop: class extends Error {
    init: super func ~tokenMessage
}


FinalInherit: class extends Error {

    first, second: FunctionDecl 

    init: func (=first, =second) {
        super(first token, "Can not inherit from final function '%s'" format(first getName()))
        next = InfoError new(second token, "...first definition was here:")
    }

}

