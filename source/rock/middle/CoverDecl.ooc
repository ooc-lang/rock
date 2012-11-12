import structs/[HashMap, ArrayList]
import ../io/TabbedWriter
import ../frontend/[Token, BuildParams]
import Expression, Type, Visitor, TypeDecl, Node, FunctionDecl,
       FunctionCall
import tinker/[Response, Resolver, Trail, Errors]

CoverDecl: class extends TypeDecl {

    fromType: Type

    init: func ~coverDeclNoSuper(.name, .token) {
        super(name, token)
    }

    init: func ~coverDecl(.name, .superType, .token) {
        super(name, superType, token)
    }

    accept: func (visitor: Visitor) { visitor visitCoverDecl(this) }

    setFromType: func (=fromType) {}
    getFromType: func -> Type { fromType }

    // all functions of a cover are final, because we don't have a 'class' field
    addFunction: func (fDecl: FunctionDecl) {
        fDecl isFinal = true
        super(fDecl)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        {
            response := super(trail, res)
            if(!response ok()) return response
        }

        trail push(this)

        if(fromType) {
            response := fromType resolve(trail, res)
            if(!response ok()) {
                fromType setRef(BuiltinType new(fromType getName(), nullToken))
            }

            if(fromType getRef() != null) {
                fromType checkedDig(res)
            }
        }

        trail pop(this)

        return Response OK
    }

    resolveCallInFromType: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        if(fromType && fromType getRef() && fromType getRef() instanceOf?(TypeDecl)) {

            tDecl := fromType getRef() as TypeDecl
            meta := tDecl getMeta()
            if(meta) {
                meta resolveCall(call, res, trail)
            } else {
                tDecl resolveCall(call, res, trail)
            }

        } else {
            -1
        }
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

