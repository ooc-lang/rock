import structs/[ArrayList, HashMap]
import Node, Type, TypeDecl, FunctionDecl, FunctionCall, Visitor, VariableAccess, PropertyDecl, ClassDecl, CoverDecl
import tinker/[Trail, Resolver, Response]

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

    functions := HashMap<String, FunctionDecl> new()

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
        hash := TypeDecl hashName(fDecl)
        functions put(hash, fDecl)
    }

    addProperty: func (vDecl: PropertyDecl) {
        properties put(vDecl name, vDecl)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(base == null) {
            baseType resolve(trail, res)
            if(baseType isResolved()) {
                base = baseType getRef() as TypeDecl
                base addons add(this)

                for(fDecl in functions) {
                    if(fDecl name == "init" && (base instanceOf?(ClassDecl) || base instanceOf?(CoverDecl))) {
                        if(base instanceOf?(ClassDecl)) base as ClassDecl addInit(fDecl)
                        else base getMeta() addInit(fDecl)
                    }
                    fDecl setOwner(base)
                }

                for(prop in properties) {
                    old := base getVariable(prop name)
                    if(old) token module params errorHandler onError(DuplicateField new(prop, old))
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
    
        hash := TypeDecl hashName(call name, call suffix)
        fDecl := functions get(hash)
        if(fDecl) {
            if(call suggest(fDecl, res, trail)) {
                // add `this` if needed.
                if(fDecl hasThis() && !call getExpr()) {
                    call setExpr(VariableAccess new("this", call token))
                }
            }
        }

        // TODO: why do we even need this?
        if(!call getSuffix()) {
            for(fDecl in functions) {
                if(fDecl name == call name) {
                    if(call suggest(fDecl, res, trail)) {
                        // success? set this if needed.
                        if(fDecl hasThis() && !call getExpr()) {
                            call setExpr(VariableAccess new("this", call token))
                        }
                    }
                }
            }
        }

        return 0
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        if(base == null) return 0

        vDecl := properties[access name]
        if(vDecl) {
            if(access suggest(vDecl)) {
                // Should I add 'this' here? :/
                // Or do some property magic?
            }
        }

        0
    }

    toString: func -> String {
        "Addon of %s in module %s" format(baseType toString(), token module getFullName())
    }

}
