import structs/[List, ArrayList, HashMap, MultiMap]
import Node, Type, TypeDecl, FunctionDecl, FunctionCall, Visitor, VariableAccess, PropertyDecl, ClassDecl, CoverDecl, BaseType, VariableDecl
import tinker/[Trail, Resolver, Response, Errors]
import ../frontend/Token

/**
 * An addon is a collection of methods added to a type via the 'extend'
 * keyword, like so:
 *
 * extend Mortal {
 *    killViolently: func { scream(); die() }
 * }
 *
 * In ooc, classes aren't open like in Rooby. We're not in a little pink
 * world where all fields and methods are hashmap values. So we're just
 * pretending they're member functions - but really, they'll only be available
 * to modules importing the module containing the 'extend' clause.
 */
Addon: class extends Node {

    doc: String = null

    // the type we're adding functions to
    baseType: Type

    base: TypeDecl { get set }

    // Map of name -> VariableDecl of our typeArgs to our classe's
    // For example, if we 'extend Foo <K>' and Foo was defined as a class <T>
    // we will have a "K" -> T: Class mapping
    typeArgMapping: HashMap<String, VariableDecl>

    // Illegal generics are the symbols that appear in the generics of our ref
    // AND do not appear in the generics of our baseType.
    illegalGenerics: ArrayList<String>

    functions := MultiMap<String, FunctionDecl> new()

    properties := HashMap<String, PropertyDecl> new()

    _stoppedAt := -1
    dummy: VariableDecl

    init: func (=baseType, .token) {
        super(token)
    }

    accept: func (v: Visitor) {
        for(f in functions) {
            f accept(v)
        }
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        false
    }

    clone: func -> This {
        Exception new(This, "Cloning of addons isn't supported")
        null
    }

    // all functions of an addon are final, because we *definitely* don't have a 'class' field
    addFunction: func (fDecl: FunctionDecl) {
        fDecl isFinal = true

        // TODO: check for redefinitions...
        functions put(fDecl getName(), fDecl)
    }

    addProperty: func (vDecl: PropertyDecl) {
        properties put(vDecl name, vDecl)
    }
    
    lookupFunction: func (fName: String, fSuffix: String = null) -> FunctionDecl {
        result: FunctionDecl
        functions getEachUntil(fName, |fDecl|
            if (fSuffix == null || fDecl getSuffixOrEmpty() == fSuffix){
                result = fDecl
                return false
            }
            true
        )
        result
    }

    checkRedefinitions: func(trail: Trail, res: Resolver){
        // Base unresolved, can not check
        if(base == null) return

        for(fDecl in functions){
            bother : FunctionDecl 
            if(!base isMeta){
                bother = base meta lookupFunction(fDecl getName(), fDecl getSuffixOrEmpty())
            } else {
                bother = base lookupFunction(fDecl getName(), fDecl getSuffixOrEmpty())
            }
            if(bother != null) res throwError(FunctionRedefinition new(fDecl, bother))
            for(addon in base getAddons()){
                other := addon lookupFunction(fDecl getName(), fDecl getSuffixOrEmpty())
                if(other != null) res throwError(FunctionRedefinition new(fDecl, other))
            }
        }
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        retry? := _stoppedAt != -1
        if(base == null || retry?) {
            // So, if we have typeArgs, we need to make sure that the generic ones are not actual types
            // because we cannot extend a realized generic type but we must rather extend the whole type.
            typeArgs? := baseType getTypeArgs() != null && !baseType getTypeArgs() empty?()

            // To get our base type's ref while using undefined typeArg types, we will point those to a
            // dummy declaration.
            // At the moment, we let the rest, that have a ref be, until we can get our base ref and do some checking.
            if (!dummy) dummy = VariableDecl new(null, "dummy", token)

            if (typeArgs? && !retry?) {
                for (typeArg in baseType getTypeArgs()) {
                    typeArg resolve(trail, res)

                    if (!typeArg getRef()) {
                        typeArg setRef(dummy)
                    }
                }
            }

            baseType resolve(trail, res)

            if (baseType isResolved()) {
                base = baseType getRef() as TypeDecl

                if (!retry?) {
                    checkRedefinitions(trail, res)
                    base addons add(this)
                }

                if (typeArgs?) {
                    // We will now check that all our generic typeArgs point to the dummy.
                    // In addition to that, we build the typeArg mapping as described on its decl.

                    // Only go through generics, not templates
                    genSize := base typeArgs size

                    if (!retry?) {
                        typeArgMapping = HashMap<String, VariableDecl> new()

                        // Start off by making all the ref generics illegal, remove as we go
                        illegalGenerics = base typeArgs map(|ta|
                            ta name
                        )
                    }

                    for ((i, typeArg) in baseType getTypeArgs()) {
                        if (i >= genSize || i < _stoppedAt) {
                            break
                        }

                        // Matched against a declaration, not good
                        if (typeArg getRef() != dummy) {
                            res throwError(ExtendRealizedGeneric new(baseType, typeArg, token))
                            return Response OK
                        }

                        // We "link" the type ourselves, to our base's generics.

                        // This is wrong.
                        // We should find where the generic was originally defined by going up the super refs.

                        //genDecl := base typeArgs get(i)
                        //typeArg setRef(genDecl)

                        superRef := base
                        genDecl := base typeArgs get(i)

                        while (superRef) {
                            superType := superRef getSuperType()
                            superRef = superRef getSuperRef()
                            if (superRef && superRef isMeta) {
                                superRef = superRef getNonMeta()
                            }

                            if (!superType || !superType isResolved() || !superRef) {
                                _stoppedAt = i
                                res wholeAgain(this, "Need all super refs and super types of addon base")
                                return Response OK
                            }

                            if (superRef isObjectClass()) {
                                break
                            }

                            // Extract the next index from the supertype
                            found? := false

                            if (superType) {
                                targs := superType getTypeArgs()
                                if (targs) for ((j, ta) in targs) {
                                    if (ta getName() == genDecl name) {
                                        found? = true
                                        genDecl = superRef typeArgs get(j)
                                    }
                                }
                            }

                            if (!found?) {
                                break
                            }
                        }


                        _stoppedAt = i + 1

                        typeArg setRef(genDecl)

                        typeArgMapping put(typeArg getName(), genDecl)

                        index := illegalGenerics indexOf(typeArg getName())
                        if (index != -1) {
                            illegalGenerics removeAt(index)
                        }

                    }
                }

                for (fDecl in functions) {
                    if(fDecl name == "init" && (base instanceOf?(ClassDecl) || base instanceOf?(CoverDecl))) {
                        if(base instanceOf?(ClassDecl)) base as ClassDecl addInit(fDecl)
                        else base getMeta() addInit(fDecl)
                    }
                    fDecl setOwner(base)
                }

                for (prop in properties) {
                    old := base getVariable(prop name)
                    if(old) token module params errorHandler onError(DuplicateField new(old, prop))
                    prop owner = base
                }
            } else {
                res wholeAgain(this, "need baseType ref")
            }
        }

        if(base == null) {
            res wholeAgain(this, "need base")
            return Response OK
        }

        finalResponse := Response OK

        trail push(this)

        for (f in functions) {
            response := f resolve(trail, res)
            if(!response ok()) {
                finalResponse = response
            }
        }

        for (p in properties) {
            response := p resolve(trail, res)
            if(!response ok()) {
                finalResponse = response
            } else {
                // all functions of an addon are final, because we *definitely* don't have a 'class' field
                if (p getter) p getter isFinal = true
                if (p setter) p setter isFinal = true
            }
        }

        trail pop(this)

        return finalResponse
    }

    // These resolve methods are called back from TypeDecl.
    resolveCallFromClass: func (call : FunctionCall, res: Resolver, trail: Trail) -> Int {
        if(base == null) return 0

        functions getEach(call name, |fDecl|
            if (call suffix && fDecl suffix != call suffix) {
                // skip it! till you make it.
                return
            }

            if (call suggest(fDecl, res, trail)) {
                if (fDecl hasThis() && !call getExpr()) {
                    // add `this` if needed.
                    call setExpr(VariableAccess new("this", call token))
                }
            }
        )

        return 0
    }

    resolveAccessFromClass: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        if(base == null) return 0

        vDecl := properties[access name]
        if(vDecl) {
            if(access suggest(vDecl)) {
                // If we are trying to access the property's variable declaration from its own getter or setter,
                //  we would need to define a new field for this type, which is impossible
                if(!vDecl inOuterSpace(trail)) {
                    res throwError(ExtendFieldDefinition new(vDecl token, "Property tries to define a field in type extension." ))
                }
            }
        }

        0
    }

    _checkInIllegal: func (name: String, tok: Token, res: Resolver) -> Bool {
        if (illegalGenerics && illegalGenerics contains?(name)) {
            // If we got up the trail so match, we didn't get any match sooner, so we error out immediately.
            ours: String = "<unknown>"
            typeArgMapping each(|src, dist|
                if (dist name == name) {
                    ours = src
                }
            )

            res throwError(IllegalGenericAccess new(name, ours, tok))
            return true
        }

        false
    }

    // These resolve functions are here to intercept attempts to use illegal generics or
    // generics we have a mapping for.
    // Then, they give up and let the base do its thing.

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        // This is true if we are accessing a field, false otherwise
        thisAccess? := access expr == null || match (access expr) {
            case va: VariableAccess =>
                va name == "this"
            case =>
                false
        }

        if (thisAccess? && _checkInIllegal(access name, access token, res)) {
            return -1
        }

        if (thisAccess? && typeArgMapping && typeArgMapping contains?(access name)) {
            if (access suggest(typeArgMapping[access name])) {
                return 0
            }
        }

        if (base) {
            return base resolveAccess(access, res, trail)
        }

        0
    }

    resolveType: func (type: BaseType, res: Resolver, trail: Trail) -> Int {
        if (_checkInIllegal(type name, type token, res)) {
            return -1
        }

        if (typeArgMapping && typeArgMapping contains?(type name)) {
            if (type suggest(typeArgMapping[type name])) {
                return 0
            }
        }

        if (base) {
            return base resolveType(type, res, trail)
        }

        0
    }

    resolveCall: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        if (base) {
            return base getMeta() resolveCall(call, res, trail)
        }

        0
    }

    toString: func -> String {
        "Addon of %s in module %s" format(baseType toString(), token module getFullName())
    }

}

ExtendFieldDefinition: class extends Error {
    init: super func ~tokenMessage
}

ExtendRealizedGeneric: class extends Error {
    baseType, realizedType: Type

    init: func (=baseType, =realizedType, .token) {
        super(token, "Trying to extend type #{baseType} with realized generic #{realizedType}, which is unsupported.")
    }
}

IllegalGenericAccess: class extends Error {
    illegalGeneric, ourGeneric: String

    init: func (=illegalGeneric, =ourGeneric, .token) {
        super(token, "Trying to use generic argument '#{illegalGeneric}', which is defined in base declaration but not the addon. You should use '#{ourGeneric}' instead.")
    }
}
