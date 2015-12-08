
// sdk stuff
import structs/[HashMap, ArrayList]
import ../io/TabbedWriter

// our stuff
import ../frontend/[Token, BuildParams]
import Expression, Type, Visitor, TypeDecl, Node, FunctionDecl,
       FunctionCall, VariableAccess, BaseType, VariableDecl
import tinker/[Response, Resolver, Trail, Errors]

CoverDecl: class extends TypeDecl {
    fromType: Type
    isProto: Bool
    isGenerated := false

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

    hasMeta?: func -> Bool {
        !template
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
            "Resolving CoverDecl #{this}, template = #{template ? template toString() : "<none>"}" println()
        }

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

