import structs/[HashMap, ArrayList]
import ../io/TabbedWriter
import ../frontend/[Token, BuildParams]
import Expression, Type, Visitor, TypeDecl, Node, FunctionDecl,
       FunctionCall
import tinker/[Response, Resolver, Trail, Errors]

CoverDecl: class extends TypeDecl {

    fromType: Type

    init: func ~coverDeclNoSuper(.name, .token) {
        init(name, null, token)
    }

    init: func ~coverDecl(.name, .superType, .token) {
        super(name, superType, token)
    }

    accept: func (visitor: Visitor) { visitor visitCoverDecl(this) }

    setFromType: func (=fromType) {
        for(addon in getAddons()) {
            addon getNonMeta() as CoverDecl setFromType(fromType)
        }
    }
    getFromType: func -> Type { fromType }

    // all functions of a cover are final, because we don't have a 'class' field
    addFunction: func (fDecl: FunctionDecl) {
        fDecl isFinal = true
        super(fDecl)
    }

    isAddon: func -> Bool { getBase() != null }

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

        return Responses OK
    }

    writeSize: func (w: TabbedWriter, instance: Bool) {
        w app("sizeof("). app(underName()). app(")")
    }

    absorb: func (node: CoverDecl, params: BuildParams) {
        if(!variables empty?()) {
            params errorHandler onError(AddingVariablesInAddon new(node, variables[0] token))
        }
        getMeta() base = node getMeta()
        //printf("%s from %s is absorbing %s from %s\n", toString(), token module toString(), node toString(), node token module toString())
        setFromType(node getFromType())
        node addAddon(this)
    }

    addAddon: func (node: CoverDecl) {
        getMeta() getAddons() add(node getMeta())
        //printf("%s from %s got %s from %s as addon\n", getMeta() toString(), token module toString(), node getMeta() toString(), node token module toString())
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
