
import structs/HashMap
import ../frontend/Token
import ../io/TabbedWriter
import Block, VariableAccess, FunctionCall, Cast, VariableDecl, TypeDecl,
       BaseType, Visitor, Node, FunctionDecl

import tinker/[Trail, Resolver, Response]

// FIXME: highly experimental. Don't touch under death penalty.

InlineContext: class extends Block {

    fCall: FunctionCall
    casted := HashMap<VariableDecl, VariableDecl> new()

    thisDecl = null, realThisDecl = null : VariableDecl

    init: func (=fCall, .token) {
        super(token)

        if(fCall expr) {
            thisTypeName := fCall expr getType() getName()
            thisType := BaseType new(thisTypeName, fCall expr token)
            thisTypeDecl := InlinedType new(this, thisTypeName)
            thisType setRef(thisTypeDecl)
            thisDecl = VariableDecl new(thisType, "this", fCall expr, fCall expr token)
            realThisDecl = VariableDecl new(null, "this", fCall expr, fCall expr token)
        }
    }

    accept: func (v: Visitor) {
        // whoopsie-daisy
        body add(0, realThisDecl)
        // as usual
        super(v)
        // there we go. nobody noticed.
        body removeAt(0)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(realThisDecl) {
            if(!realThisDecl resolve(trail, res) ok()) return Responses OK
        }

        super(trail, res)

    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        "====================================" println()
        "In inline context of %s, looking for access %s" printfln(fCall toString(), access toString())

        if(fCall expr != null) {
            exprType := fCall expr getType()
            if(exprType != null && exprType getRef() != null) {
                ref := exprType getRef()
                "ref is %s" printfln(ref toString())

                if(access getName() == "this") {
                    if(access suggest(thisDecl)) {
                        "We did it, honey!" println()
                        return 0
                    }
                }

                proxy := access clone() as VariableAccess
                ref resolveAccess(proxy, res, trail)
                if(proxy ref != null) {
                    "resolved to %s" printfln(proxy ref toString())
                    targetType := proxy ref getType()
                    realType := targetType realTypize(fCall)

                    suggestion : VariableDecl = null
                    if(targetType equals?(realType)) {
                        "Equal types! suggesting %s" printfln(proxy ref toString())
                        suggestion = proxy ref
                    } else {
                        "Casting! targetType = %s, realType = %s" printfln(targetType toString(), realType toString())
                        // 1 = after this :) hackhackhack!
                        realtypized := VariableDecl new(null, proxy getName(), Cast new(proxy, realType, proxy ref token), proxy ref token)
                        realtypized owner = fCall ref owner

                        varAcc := VariableAccess new("this", nullToken)
                        varAcc ref = realThisDecl
                        proxy expr = varAcc

                        casted put(proxy ref as VariableDecl, realtypized) // TODO: use that later, in case of multiple access
                        body add(1, realtypized)
                        suggestion = realtypized
                    }
                    if(suggestion != null && access suggest(suggestion)) {
                        " - Suggestion worked o/" println()
                        return 0
                    }
                }
            }
        }

        super(access, res, trail)
    }

    toString: func -> String {
        ("[InlineContext of %s] " format(fCall toString())) + super()
    }

}

InlinedType: class extends TypeDecl {

    context: InlineContext

    init: func ~inlinedType (=context, .name) {
        super("<Inlined " + name + ">", null, nullToken)
    }

    clone: func -> This {
        this
    }

    underName: func -> String { name }

    accept: func (v: Visitor) { /* yeah, right. */ }

    writeSize: func (w: TabbedWriter, instance: Bool) { Exception new(This, "writeSize() called on an InlinedType. wtf?") throw() /* if this happens, we're screwed */ }

    replace: func (oldie, kiddo: Node) -> Bool { false }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        "====================================" println()
        "In inlined type %s, looking for access %s" printfln(toString(), access toString())

        if(access expr instanceOf?(VariableAccess)) {
            varAcc := access expr as VariableAccess
            if(varAcc getName() == "this") {
                access expr = null // mwahahaha.
                context resolveAccess(access, res, trail)
                varAcc = VariableAccess new("this", access token)
                varAcc ref = context realThisDecl
                access expr = varAcc // hahahahahahaaaaaaaaaaaaaa!!
                "We now have access %s" printfln(access toString())
                "expr getType() getRef() is a %s" printfln(access expr getType() getRef() class name)
                "...and it's %s" printfln(access expr getType() getRef() toString())
            }
        }

        return 0
    }

}




