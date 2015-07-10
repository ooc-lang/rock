import structs/[List, ArrayList]

import ../backend/cnaughty/AwesomeWriter, ../frontend/[BuildParams, Token]
import tinker/[Response, Resolver, Trail, Errors]

import Type, Declaration, VariableAccess, VariableDecl, TypeDecl,
       InterfaceDecl, Node, ClassDecl, CoverDecl, Cast, FuncType,
       FunctionCall, Module, NamespaceDecl, Match

/**
 * BaseType(s) are types that are neither pointers, nor references.
 * This has nothing to do with the "primitive" (covers) vs "object" (class)
 * distinction.
 */
BaseType: class extends Type {
    cloneDepth := static 0

    namespace: VariableAccess = null

    ref: Declaration = null

    name: String

    _floatingPoint := NumericState UNKNOWN
    _integer := NumericState UNKNOWN

    void? : Bool {
        get { super() || name == "void" || name == "Void" }
    }

    typeArgs: List<TypeAccess> = null

    init: func ~baseType (=name, .token) {
        super(token)
    }

    init: func ~withNamespace (=name, =namespace, .token) {
        super(token)
    }

    /**
     * For internal use, override with someting like
     * 
     *   name == "Kalamazoo"
     *
     * ..or another unique name, and use that name in the code
     * you're trying to compile, to get additional debug output
     * from rock.
     */
    debugCondition: final func -> Bool {
        false
    }

    pointerLevel: func -> Int { 0 }

    isPointer: func -> Bool { name == "Pointer" }

    equals?: func (other: This) -> Bool {
        if (other class != this class) return false
        return (other as BaseType name equals?(name))
    }

    addTypeArg: func (typeArg: TypeAccess) -> Bool {
        if (!typeArgs) typeArgs = ArrayList<TypeAccess> new()
        typeArgs add(typeArg clone())
        true
    }

    getName: func -> String { name }

    suggest: func (decl: Declaration) -> Bool {

        if (debugCondition()) {
            "Suggested %s for %s" printfln(decl toString(), toString())
        }

        match decl {
            case tDecl: TypeDecl =>
                if (tDecl isAddon()) {
                    // The second rule of resolve club is: you do *NOT* resolve to an addon.
                    // Always resolve to the base instead.
                    return suggest(tDecl getBase() getNonMeta())
                }

                match decl {
                    case cDecl: CoverDecl =>
                        if (cDecl template) {
                            return suggest(cDecl getTemplateInstance(this))
                        }
                }
        }

        ref = decl

        if (name == "This" && getRef() instanceOf?(TypeDecl)) {
            tDecl := getRef() as TypeDecl
            name = tDecl getName()
        }
        return true
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if (isResolved()) {
            if (ref token module && ref token module dead) {
                "%s outdated from module %s, re-resolving!" printfln(name, ref token module fullName)
                ref = null
                res wholeAgain(this, "re-resolved because of dead module")
            } else {
                return Response OK
            }
        }

        if (namespace) {

            trail push(this)
            response := namespace resolve(trail, res)
            trail pop(this)
            if (!response ok()) {
                if (res params veryVerbose) "Failed to resolve expr %s of type %s, looping" printfln(namespace toString(), toString())
                return response
            }

            if (namespace getRef() != null && namespace getRef() instanceOf?(NamespaceDecl)) {
                namespace getRef() as NamespaceDecl resolveType(this, res, trail)
            } else {
                res throwError(InvalidNamespaceAccess new(token, this, "Trying to access a type from %s, which is not a namespace" format(namespace toString())))
            }
        }

        if (typeArgs) {
            trail push(this)
            for (typeArg in typeArgs) {
                response := typeArg resolve(trail, res)
                if (!response ok()) {
                    trail pop(this)
                    return response
                }
            }
            trail pop(this)
        }

        if (!ref) {
            depth := trail getSize() - 1
            while(depth >= 0) {
                node := trail get(depth, Node)
                node resolveType(this, res, trail)
                if (ref) {
                    break // break on first match
                }
                depth -= 1
            }
        }

        if (!ref) {
            if (res fatal) {
                if (res params veryVerbose) {
                    trail toString() println()
                }

                msg := "Undefined type '%s'" format(getName())
                similar := findSimilar(res)
                if (similar) msg += similar
                res throwError(UnresolvedType new(token, this, msg))
            }
            if (res params veryVerbose) {
                "     - type %s still not resolved, looping (ref = %p)" printfln(name, getRef())
            }
            return Response LOOP
        }
        
        checkMismatchedTypeParams(trail, res)

        return Response OK

    }

    _checkMismatchDone := false

    checkMismatchedTypeParams: func (trail: Trail, res: Resolver) {
        parent := trail peek()
        match parent {
            case ta: TypeAccess =>
                // don't check for mismatch, it's a particular case, see #802
                _checkMismatchDone = true
                return

            case cast: Cast =>
                // same, don't care for mismatches when casting
                _checkMismatchDone = true
                return
        }

        match ref {
            case tDecl: TypeDecl =>
                if (tDecl isMeta || tDecl getTypeArgs() empty?()) {
                    // nothing to check
                    _checkMismatchDone = true
                    return
                }

                numDeclTypeArgs := tDecl getTypeArgs() getSize()
                numTypeArgs := typeArgs == null ? 0 : typeArgs size

                if (numTypeArgs != numDeclTypeArgs) {
                    quantity : String = match {
                        case numTypeArgs < numDeclTypeArgs =>
                            "Too few"
                        case =>
                            "Too many"
                    }

                    model := tDecl name + tDecl typeArgsRepr()
                    token printMessage("our parent is a #{parent}")
                    msg := "#{quantity} type parameters for #{this}. It should match #{model}"
                    err := MismatchedTypeParams new(token, msg)
                    res throwError(err)
                }
        }

    }

    findSimilar: func (res: Resolver) -> String {

        buff := Buffer new()

        for (imp in res collectAllImports()) {
            module := imp getModule()

            type := module getTypes() get(name)
            if (type) {
                buff append(" (Hint: there's such a type in "). append(imp getPath()). append(")")
            }
        }

        buff toString()

    }

    isResolved: func -> Bool {
        if (ref == null) return false
        if (ref token module && ref token module dead) return false
        if (typeArgs == null) return true
        for (typeArg in typeArgs) if (!typeArg isResolved()) {
            return false
        }
        return true
    }

    getRef: func -> Declaration { ref }
    setRef: func (=ref) {}

    getTypeArgs: func -> List<TypeAccess> { typeArgs }

    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        // if (debugCondition()) {
        //     token printMessage("#{this} vs #{other}, other isGeneric #{other isGeneric()}, pointerLevel ? #{other pointerLevel()}, isPointer() ? #{isPointer()}, other isPointer() ? #{other isPointer()}\n")
        // }

        while (other instanceOf?(TypeAccess)) {
            other = other as TypeAccess inner
        }

        if (void?) {
            // only void matches with void.
            return (other void?) ? scoreSeed : This NOLUCK_SCORE
        }

        ourRef := getRef()
        if (!ourRef) return -1
        
        hisRef := other getRef()
        if (!hisRef) return -1

        if (other isGeneric() && other pointerLevel() == 0) {
            // every type is always a match against a flat generic type
            return scoreSeed
        }

        if (isGeneric() && other isPointer()) {
            // a generic value is a match for a pointer
            return scoreSeed / 2
        }

        if (isPointer() && hisRef instanceOf?(ClassDecl)) {
            // objects are references in ooc
            return scoreSeed / 4
        }

        if (ourRef instanceOf?(ClassDecl) && other isPointer()) {
            // objects are still references in ooc
            return scoreSeed / 4
        }

        ground := other getGroundType()
        if (isPointer() && (ground isPointer() || ground pointerLevel() > 0)) {
            // two pointers = okay
            return scoreSeed / 2
        }

        superType: Type = null
        match ourRef {
            case td: TypeDecl =>
                superType = td getSuperType()
        }

        lhsCoverDecl := ourRef instanceOf?(CoverDecl)
        rhsCoverDecl := hisRef instanceOf?(CoverDecl)

        if (lhsCoverDecl && rhsCoverDecl) {
            lhsCover := ourRef as CoverDecl
            rhsCover := hisRef as CoverDecl
            if (lhsCover == rhsCover) {
                // all good
                return scoreSeed
            }
        }

        // compare generic type arguments
        lhsTypeArgs := getTypeArgs()
        rhsTypeArgs := other getTypeArgs()

        // one has, other doesn't? no luck
        if ((lhsTypeArgs == null) != (rhsTypeArgs == null)) {
            // if (debugCondition()) { token printMessage("one has, other doesn't") }
            if (superType) {
                return superType getScore(other)
            } else {
                return This NOLUCK_SCORE
            }
        }

        if ((lhsTypeArgs != null) && (rhsTypeArgs != null)) {
            // if (debugCondition()) { token printMessage("both have!") }
            if (lhsTypeArgs size != rhsTypeArgs size) {
                // if (debugCondition()) { token printMessage("number mismatch") }
                // mismatch in numbers
                if (superType) {
                    return superType getScore(other)
                } else {
                    return This NOLUCK_SCORE
                }
            }

            for ((i, lhsArg) in lhsTypeArgs) {
                rhsArg := rhsTypeArgs[i]

                if (lhsArg == null) {
                    return -1
                }
                if (rhsArg == null) {
                    return -1
                }
                innerScore := lhsArg getScore(rhsArg)

                if (innerScore < 0) {
                    if (superType) {
                        return superType getScore(other)
                    } else {
                        return innerScore
                    }
                }
            }
        }
        
        if (other instanceOf?(BaseType)) {
            if (ourRef == hisRef) {
                // perfect match
                return scoreSeed
            }

            // if we are one of his addons, we're good
            if (hisRef instanceOf?(TypeDecl)) {
                for (addon in hisRef as TypeDecl getAddons()) {
                    hisRef2 := addon base
                    //printf("Reviewing addon %s, ref %s (%s), vs %s (%s)\n", addon getNonMeta() toString(), ourRef toString(), ourRef token toString(), hisRef toString(), hisRef token toString())
                    if (ourRef == hisRef2) {
                        // perfect match
                        return scoreSeed
                    }
                }
            }

            if (ourRef instanceOf?(TypeDecl) && hisRef instanceOf?(TypeDecl)) {
                inheritsScore := ourRef as TypeDecl inheritsScore(hisRef as TypeDecl, scoreSeed - 2)

                // something needs resolving
                if (inheritsScore == -1) {
                    return -1
                }

                bothCovers := ourRef instanceOf?(CoverDecl) && hisRef instanceOf?(CoverDecl)
                if (inheritsScore <= 0 && bothCovers) {
                    // well, try the other way around - covers are lax - but it'll be weaker this time
                    inheritsScore = hisRef as TypeDecl inheritsScore(ourRef as TypeDecl, scoreSeed / 2)
                }

                // cool, a match =)
                if (inheritsScore > 0) {
                    return inheritsScore
                }
            }

            lhsInt := getIntegerState()
            if (lhsInt == NumericState UNKNOWN) return -1
            rhsInt := other getIntegerState()
            if (rhsInt == NumericState UNKNOWN) return -1

            lhsFp := getFloatingPointState()
            if (lhsFp == NumericState UNKNOWN) return -1
            rhsFp := other getFloatingPointState()
            if (rhsFp == NumericState UNKNOWN) return -1

            lhsNum := (lhsInt == NumericState YES || lhsFp == NumericState YES)
            rhsNum := (rhsInt == NumericState YES || rhsFp == NumericState YES)

            if (lhsNum && rhsNum) {
                if (rhsFp == NumericState YES) {
                    // it's better to fit an int into a double than the other way around
                    // because we lose less precision.
                    return scoreSeed / 4
                } else {
                    // a mild match - it's not too good to mix integer types. Maybe we need more safety here?
                    return scoreSeed / 8
                }
            }
        }

        return This NOLUCK_SCORE // no luck.
    }

    _theoreticalTypeWidth := -1

    getTheoreticalTypeWidth: func -> Int {
        if (_theoreticalTypeWidth == -1) {
           _computeTheoreticalTypeWidth() 
        }
        _theoreticalTypeWidth
    }

    _computeTheoreticalTypeWidth: func {
        simpleName := name replaceAll("unsigned ", "")

        _theoreticalTypeWidth = match simpleName {
            case "float" => 4
            case "double" => 8
            case "long double" => 16

            case "char" => 1
            case "short" => 2
            case "int" => 4
            case "long" => 8
            case "long long" => 16

            case => 0
        }

        if (_theoreticalTypeWidth != 0) {
            return
        }

        if (getRef() == null) {
            // can't dig
            return
        }
        down := dig()
        while (down) {
            _theoreticalTypeWidth = down getTheoreticalTypeWidth()

            if (_theoreticalTypeWidth != 0) {
                return
            }

            if (down getRef() == null) {
                // can't dig, still unsure
                return
            }
            down = down dig()
        }
    }

    _computeFloatingPointState: func {
        if (name == "double" || name == "float" || name == "long double") {
            _floatingPoint = NumericState YES
            return
        }

        if (getRef() == null) {
            // can't dig
            return
        }
        down := dig()
        while (down) {
            match (down getFloatingPointState()) {
                case NumericState YES =>
                    // good, then we are too
                    _floatingPoint = NumericState YES
                    return
                case NumericState UNKNOWN =>
                    // we can't tell yet.
                    return
                case =>
                    // keep digging!
            }

            if (down getRef() == null) {
                // can't dig, still unsure
                return
            }
            down = down dig()
        }

        // we went the distance, and no, we're not.
        _floatingPoint = NumericState NO
    }

    _computeIntegerState: func {
        if ((name endsWith?(" long") || name == "long" || name endsWith?(" int") || name == "int" || name endsWith?(" short") || name == "short" ||
          ((name startsWith?("int") || name startsWith?("uint")) && name endsWith?("_t")) || name == "size_t" || name == "ssize_t")) {
            _integer = NumericState YES
            return
        }

        if (getRef() == null) {
            // can't dig
            return
        }
        down := dig()
        while (down) {
            match (down getIntegerState()) {
                case NumericState YES =>
                    // good, then we are too
                    _integer = NumericState YES
                    return
                case NumericState UNKNOWN =>
                    // we can't tell yet.
                    return
                case =>
                    // keep digging!
            }

            if (down getRef() == null) {
                // can't dig, still unsure.
                return
            }
            down = down dig()
        }

        // we went the distance, and no, we're not.
        _integer = NumericState NO
    }

    getFloatingPointState: func -> NumericState {
        if (_floatingPoint == NumericState UNKNOWN) {
            _computeFloatingPointState()
        }
        _floatingPoint
    }

    getIntegerState: func -> NumericState {
        if (_integer == NumericState UNKNOWN) {
            _computeIntegerState()
        }
        _integer
    }

    dereference: func -> Type {
        digged := dig()
        if (digged) {
            return digged dereference()
        }
        null
    }

    clone: func -> This {
        if (cloneDepth > 25) {
            raise("clone loop!")
        }

        cloneDepth += 1

        copy := new(name, token)
        if (getTypeArgs()) for (typeArg in getTypeArgs()) {
            copy addTypeArg(typeArg clone())
        }

        copy setRef(getRef())

        cloneDepth -= 1

        copy
    }

    dig: func -> Type {
        if (getRef() != null && getRef() instanceOf?(CoverDecl)) {
            return ref as CoverDecl getFromType()
        }
        return null
    }

    checkedDigImpl: func (list: List<Type>, res: Resolver) {
        if (getRef() == null) {
            res wholeAgain(this, "Null ref while check-digging")
            return
        }

        list add(this)

        if (getRef() != null && getRef() instanceOf?(CoverDecl)) {
            next := ref as CoverDecl getFromType()
            if (next != null) {
                if (list contains?(next)) {
                    buff := Buffer new()
                    isFirst := true
                    for (t in list) {
                        if (!isFirst) buff append(" -> ")
                        buff append(t toString())
                        isFirst = false
                    }
                    res throwError(CoverDeclLoop new(list first() token, "Loop in cover declaration: %s -> %s -> ..." format(buff toString(), next toString(), list getSize())))
                }
                next checkedDigImpl(list, res)
            }
        }
    }

    inheritsFrom?: func (t: Type) -> Bool {
        if (!t instanceOf?(BaseType)) return false
        bt := t as BaseType
        if (   ref == null || !   ref instanceOf?(TypeDecl)) return false
        if (bt ref == null || !bt ref instanceOf?(TypeDecl)) return false

        return ref as TypeDecl inheritsFrom?(bt ref as TypeDecl)
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        if (typeArgs) return typeArgs replace(oldie as TypeAccess, kiddo as TypeAccess)
        false
    }

    toString: func -> String {
        if (typeArgs == null) return getName()

        sb := Buffer new()
        sb append(getName())
        sb append("<")
        isFirst := true
        if (typeArgs) for (typeArg in typeArgs) {
            if (isFirst) isFirst = false
            else        sb append(", ")
            sb append(typeArg toString())
        }
        sb append(">")
        return sb toString()
    }

    searchTypeArg: func (typeArgName: String, finalScore: Int@) -> Type {
        if (getRef() == null) {
            finalScore = -1
            return null
        }

        if (!getRef() instanceOf?(TypeDecl)) {
            // only TypeDecl have typeArgs anyway.
            return null
        }

        typeRef := getRef() as TypeDecl

        j := 0
        for (arg in typeRef typeArgs) {
            if (arg getName() == typeArgName) {
                //printf("Looking for %s in %s (ref %s), candidate = %s, j = %d, typeArgs size() = %d\n", typeArgName, toString(), typeRef toString(), arg getName(), j, typeArgs ? typeArgs size() : -1)
                if (typeArgs == null || typeArgs getSize() <= j) {
                    continue
                }
                candidate := typeArgs get(j)
                ref := candidate getRef()
                if (ref == null) return null
                result : Type = null

                //printf("Found candidate %s (which is a %s) for typeArg %s, ref is a %s, = %s\n", candidate toString(), candidate class name, typeArgName, ref class name, ref toString())
                if (ref instanceOf?(TypeDecl)) {
                    // resolves to a known type
                    result = ref as TypeDecl getInstanceType() clone()

                    downResult := result
                    // TODO: doing that a lot, need a method or something.. -- amos
                    while (downResult instanceOf?(TypeAccess)) {
                        downResult = downResult as TypeAccess inner
                    }
                    match downResult {
                        case baseType: BaseType =>
                            if (baseType typeArgs) {
                                // translate into our own typeArgs
                                if (candidate getTypeArgs() == null) raise("expected non-null typeArgs")
                                for ((i, typeArg) in candidate getTypeArgs()) {
                                    if (i > baseType typeArgs size) {
                                        raise("#{i} > #{baseType typeArgs size} (missing typeArgs in typeDecl ref result)")
                                    }
                                    baseType typeArgs set(i, typeArg)
                                }
                            }
                    }
                } else if (ref instanceOf?(VariableDecl)) {
                    // resolves to an access to another generic type
                    result = BaseType new(ref as VariableDecl getName(), token)
                    result setRef(ref) // FIXME: that is experimental. is that a good idea?
                } else if (ref instanceOf?(FuncType)) {
                    //printf("ref of %s is a %s!\n", candidate toString(), ref class name)
                    result = ref as FuncType
                }
                return result
            }
            j += 1
        }

        // translate things like:
        // HashMap<K, V> extends Iterator<V>
        current := typeRef
        while(current != null && current getSuperType() != null) {
            result := searchInheritance(typeArgName, current, current getSuperType(), finalScore&)
            if (finalScore == -1) return null
            if (result) return result
            current = current getSuperRef()
        }

        for (interfaceType in typeRef interfaceTypes) {
            result := searchInheritance(typeArgName, typeRef, interfaceType, finalScore&)
            if (finalScore == -1) return null
            if (result) return result
        }

        superType := typeRef getSuperType()
        if (superType != null) {
            //printf("Searching for <%s> in super-type %s\n", typeArgName, superType toString())
            return superType searchTypeArg(typeArgName, finalScore&)
        }

        return null
    }

    searchInheritance: func (typeArgName: String, current: TypeDecl, superType: Type, finalScore: Int@) -> Type {

        j := 0
        superRef := superType getRef() as TypeDecl
        if (superRef == null) {
            finalScore = -1
            return null // something needs to be resolved further
        }

        superArgs := superRef getTypeArgs()
        for (superArg in superArgs) {
            if (superArg getName() == typeArgName) {
                superRealArgs := superType getTypeArgs()
                if (superRealArgs == null || superRealArgs getSize() < j) {
                    continue
                }
                candidate := superRealArgs get(j)

                ref := candidate getRef()

                if (ref == null) {
                    finalScore = -1
                    return null
                }
                result : Type = null

                if (ref instanceOf?(TypeDecl)) {
                    // resolves to a known type
                    result = ref as TypeDecl getInstanceType()
                } else if (ref instanceOf?(VariableDecl)) {
                    // resolves to an access to another generic type
                    result = BaseType new(ref as VariableDecl getName(), token)
                    result setRef(ref) // FIXME: that is experimental. is that a good idea?
                }
                return result
            }
            j += 1
        }

        null
    }

    realTypize: func (call: FunctionCall) -> Type {
        finalScore := 0
        solved := call resolveTypeArg(null, null, name, finalScore&)
        if (solved) return solved
        this
    }

    setNamespace: func (=namespace) {}

    templateAbsolute: func -> This {
        c := clone()
        match (c ref) {
            case td: TypeDecl =>
                c name = td name
        }
        c
    }

    /* BACKEND FUNCTIONS */

    /*
     * The following functions don't belong in middle/ at all... they're used
     * by the C backend to write types to C header or source files.
     */

    write: func (w: AwesomeWriter, name: String) {
        if (getRef() == null) {
            Exception new(This, "Trying to write unresolved type " + toString()) throw()
        }
        match {
            case getRef() instanceOf?(InterfaceDecl)=> writeInterfaceType(w, getRef() as InterfaceDecl)
            case getRef() instanceOf?(TypeDecl)     => writeRegularType  (w, getRef() as TypeDecl)
            case getRef() instanceOf?(VariableDecl) => writeGenericType  (w, getRef() as VariableDecl)
        }
        if (name != null) w app(' '). app(name)
    }

    writeInterfaceType: func (w: AwesomeWriter, id: InterfaceDecl) {
        w app(id getFatType() getInstanceType())
    }

    writeRegularType: func (w: AwesomeWriter, td: TypeDecl) {

        if (td isExtern()) {
            if (td instanceOf?(CoverDecl)) {
                cDecl := getRef() as CoverDecl
                fromType := cDecl getFromType()
                if (fromType != null && cDecl isExtern()) {
                    // for extern covers, write directly the underlying
                    // type - since we don't even write a typedef.
                    w app(fromType getGroundType() toString())
                    return
                }
            }

            // still have a chance to have an extern name
            w app(td getExternName())
            return
        }

        while(td instanceOf?(CoverDecl) && td as CoverDecl isAddon()) {
            td = td as CoverDecl getBase() getNonMeta()
        }

        w app(td underName())
        if (td instanceOf?(ClassDecl)) {
            w app('*')
        }
    }

    writeGenericType: func (w: AwesomeWriter, vd: VariableDecl) {
        w app("uint8_t*")
    }

}

/**
 * VoidType is simply more comfortable to instanciate from within the
 * compiler than having to instanciate a BaseType and set its ref
 * so we don't wait for it to resolve!
 */
VoidType: class extends BaseType {

    init: func {
        super("void", nullToken)
        ref = BuiltinType new("void", nullToken)
    }

    clone: func -> This {
        this
    }

}

/* ROCK COMPILE-TIME ERRORS */

UnresolvedType: class extends Error {
    type: Type

    init: func (.token, =type, .message) {
        super(token, message)
    }
}

MismatchedTypeParams: class extends Error {
    init: super func ~tokenMessage
}

InvalidNamespaceAccess: class extends Error {
    type: Type

    init: func (.token, =type, .message) {
        super(token, message)
    }
}

