import structs/[List, ArrayList, HashMap, MultiMap]
import Node, Type, TypeDecl, FunctionDecl, FunctionCall, Visitor, VariableAccess, PropertyDecl, ClassDecl, CoverDecl, BaseType
import tinker/[Trail, Resolver, Response, Errors]

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

    // typeArgs of our baseType
    typeArgs: List<TypeAccess>

    functions := MultiMap<String, FunctionDecl> new()

    properties := HashMap<String, PropertyDecl> new()

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

        if(base == null) {

            // If we have a base type base, then we will do somehting a little bit special.
            // We will take its typeArgs off, resolve it that way, then resolve through the generic typeArgs
            // and error out if they can get a ref (we want to extend generically, can't extend a realized type)
            typeArgs = match baseType {
                case bt: BaseType =>
                    typeArgs := bt typeArgs
                    bt = bt clone()
                    bt typeArgs = null
                    typeArgs
                case =>
                    null
            }

            baseType resolve(trail, res)

            if(baseType isResolved()) {
                base = baseType getRef() as TypeDecl
                checkRedefinitions(trail, res)
                base addons add(this)

                if (typeArgs) {
                    // Only go through generics, not templates too

                    // But first, let's check our count
                    // baseTArgCount := base typeArgs size + match (base templateParent)

                    genSize := base typeArgs size

                    for ((i, typeArg) in typeArgs) {
                        if (i >= genSize) {
                            break
                        }

                        typeArg resolve(trail, res)

                        // Matched against a typeDecl, not good
                        if (typeArg getRef() != null) {
                            res throwError(ExtendRealizedGeneric new(baseType, typeArg, token))
                            return Response OK
                        }
                    }
                }

                for(fDecl in functions) {
                    if(fDecl name == "init" && (base instanceOf?(ClassDecl) || base instanceOf?(CoverDecl))) {
                        if(base instanceOf?(ClassDecl)) base as ClassDecl addInit(fDecl)
                        else base getMeta() addInit(fDecl)
                    }
                    fDecl setOwner(base)
                }

                for(prop in properties) {
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
        trail push(base getMeta())
        for(f in functions) {
            response := f resolve(trail, res)
            if(!response ok()) {
                finalResponse = response
            }
        }
        for(p in properties) {
            response := p resolve(trail, res)
            if(!response ok()) {
                finalResponse = response
            } else {
                // all functions of an addon are final, because we *definitely* don't have a 'class' field
                if(p getter) p getter isFinal = true
                if(p setter) p setter isFinal = true
            }
        }
        trail pop(base getMeta())

        return finalResponse
    }

    resolveCall: func (call : FunctionCall, res: Resolver, trail: Trail) -> Int {
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

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
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
