
// sdk stuff
import structs/[HashMap, ArrayList]
import ../io/TabbedWriter

// our stuff
import ../frontend/[Token, BuildParams]
import Expression, Type, Visitor, TypeDecl, Node, FunctionDecl,
       FunctionCall, VariableAccess, TemplateDef, BaseType, VariableDecl
import tinker/[Response, Resolver, Trail, Errors]

CoverDecl: class extends TypeDecl {

    fromType: Type
    isProto: Bool
    isGenerated := false

    template: TemplateDef { get set }
    templateParent: CoverDecl { get set }

    instances: HashMap<String, CoverDecl>

    fromClosure := false

    init: func ~coverDeclNoSuper(.name, .token) {
        super(name, token)
    }

    init: func ~coverDecl(.name, .superType, .token) {
        super(name, superType, token)
    }

    isPrimitiveType: func -> Bool {
        true
    }

    accept: func (visitor: Visitor) { visitor visitCoverDecl(this) }

    setFromType: func (=fromType) {}
    getFromType: func -> Type { fromType }

    setProto: func (=isProto) {}

    // all functions of a cover are final, because we don't have a 'class' field
    addFunction: func (fDecl: FunctionDecl) {
        fDecl isFinal = true
        super(fDecl)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        if (debugCondition()) {
            "Resolving CoverDecl #{this}, template = #{template}" println()
        }

        if (template) {
            response := Response OK

            if (instances) for (instance in instances) {
                if (debugCondition()) {
                    "Resolving instance #{instance}" println()
                }
                response = instance resolve(trail, res)

                if (!response ok()) {
                    return response
                }
            }
        } else {
            // resolve the body, methods, arguments
            response := super(trail, res)
            if(!response ok()) return response

            if(fromType) {
                trail push(this)
                response := fromType resolve(trail, res)
                if(!response ok()) {
                    fromType setRef(BuiltinType new(fromType getName(), nullToken))
                }

                if(fromType getRef() != null) {
                    fromType checkedDig(res)
                }
                trail pop(this)
            }
        }

        return Response OK
    }

    resolveCall: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        if(fromType && fromType getRef() && fromType getRef() instanceOf?(TypeDecl)) {
            tDecl := fromType getRef() as TypeDecl
            meta := tDecl getMeta()
            if(meta) {
                meta resolveCall(call, res, trail)
            } else {
                tDecl resolveCall(call, res, trail)
            }
        }

        if(!call ref) {
            return super(call, res, trail)
        }
        0
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        if(fromType && fromType getRef() && fromType getRef() instanceOf?(TypeDecl)) {
            // Try to find out if we are covering a pointer so we can throw a "need dereferencing" error
            burrowedFrom := fromType
            while(burrowedFrom) {
                if(!burrowedFrom getRef()) return -1

                if(burrowedFrom class == PointerType) {
                    return 0 // we can't access stuff in covers from pointer types
                }

                if(!burrowedFrom getRef() instanceOf?(This)) break
                burrowedFrom = burrowedFrom getRef() as This fromType
            }

            fromType getRef() as TypeDecl resolveAccess(access, res, trail)
        }

        if(!access ref) {
            return super(access, res, trail)
        }
        0
    }

    hasMeta?: func -> Bool {
        if (debugCondition()) {
            "hasMeta called, they want %s / %p back" printfln(toString(), template)
        }

        // templates have no meta-class. Like, none at all.
        !template
    }

    _getFingerprint: func (spec: BaseType) -> String {
        buffer := Buffer new()
        buffer append("__"). append(name)

        for (i in 0..spec typeArgs size) {
            theirs := spec typeArgs get(i)
            ours   := template typeArgs get(i)

            buffer append("__")

            if (theirs inner isGeneric()) {
                buffer append(ours getName())
            } else {
                buffer append(theirs getName())
            }
        }

        buffer toString()
    }

    getTemplateInstance: func (spec: BaseType) -> CoverDecl {
        fingerprint := _getFingerprint(spec)

        if (instances && instances contains?(fingerprint)) {
            return instances get(fingerprint)
        }

        instance := This new(fingerprint, token)
        instance templateParent = this
        instance module = module
        instance setVersion(instance getVersion())

        i := 0
        for (typeArg in spec typeArgs) {
            if (i >= template typeArgs size) {
                Exception new("Too many template args for %s" format(toString())) throw()
            }

            name := template typeArgs get(i) getName()
            ref := typeArg getRef()

            if (typeArg inner isGeneric()) {
                thisRef := VariableDecl new(typeArg inner getRef() getType(), name, spec token)
                instance addTypeArg(thisRef)
            } else {
                instance templateArgs put(name, ref)
            }

            i += 1
        }

        for (variable in variables) {
            instance addVariable(variable clone())
        }

        for (oDecl in operators) {
            instance addOperator(oDecl clone())
        }

        for (fDecl in getMeta() functions) {
            if (fDecl oDecl) {
                // already been added at last step
                continue
            }

            if (fDecl autoNew) {
                // let autoNew do its thing in CoverDecl
                continue
            }

            fDeclClone := fDecl clone()
            fDeclClone owner = null

            instance addFunction(fDeclClone)
        }

        if (!instances) {
            instances = HashMap<String, CoverDecl> new()
        }

        if (token module params debugTemplates) {
            "Instanciated #{fingerprint} => #{instance}" println()
            meta := instance getMeta()
            for (f in meta functions) {
                "- #{f}" println()
            }
        }
        instances put(fingerprint, instance)

        instance
    }

    writeSize: func (w: TabbedWriter, instance: Bool) {
        w app("sizeof("). app(underName()). app(")")
    }

    replace: func (oldie, kiddo: Node) -> Bool { false }

}

AddingVariablesInAddon: class extends Error {

    init: func (base: CoverDecl, =token) {
        message = base token formatMessage("...while extending cover " + base toString(), "") +
                       token formatMessage("Attempting to add variables to another cover!", "ERROR")
    }

    format: func -> String {
        message
    }

}

CoverDeclLoop: class extends Error {
    init: super func ~tokenMessage
}

