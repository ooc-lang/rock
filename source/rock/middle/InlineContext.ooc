
import structs/[ArrayList, HashMap]
import ../frontend/Token
import ../io/TabbedWriter
import Block, VariableAccess, FunctionCall, Cast, VariableDecl, TypeDecl,
       BaseType, Visitor, Node, FunctionDecl, Type

import tinker/[Trail, Resolver, Response]

// FIXME: highly experimental. Don't touch under death penalty.

InlineContext: class extends Block {

    returnType : Type
    returnArgs := ArrayList<VariableDecl> new()

    fCall: FunctionCall
    ref: FunctionDecl
    casted := HashMap<VariableDecl, VariableDecl> new()

    thisDecl = null, realThisDecl = null : VariableDecl

    init: func (=fCall, .token) {
        super(token)

        // Store the ref on our own, just in case
        ref = fCall ref

        if(fCall expr) {
            // We use a fake 'this' to intercept variable access resolution
            // and substitute generic types with real types
            thisTypeName := fCall expr getType() getName()
            thisType := BaseType new(thisTypeName, fCall expr token)
            thisTypeDecl := InlinedType new(this, thisTypeName)
            thisType setRef(thisTypeDecl)
            thisDecl = VariableDecl new(thisType, "this", fCall expr, fCall expr token)
            realThisDecl = VariableDecl new(null, "this", fCall expr, fCall expr token)
        }

        "== Inline context of %s's ref has %d, and fCall has %d! ==" printfln(toString(), fCall ref getReturnArgs() size(), fCall getReturnArgs() size())
        returnType = ref returnType realTypize(fCall)
        "Return type of ref is %s, ours is %s" printfln(ref returnType toString(), returnType toString())

    }

    accept: func (v: Visitor) {
        // here we play a little trick on our backend generator:
        // the real this decl has to be written if we're a member call,
        // because, you know, otherwise this can't be accessed.
        // but since we have been using a fake 'this' to intercept
        // variable access resolution, we weren't able to simply add
        // it to the body during the resolution phase (the real 'this'
        // would've been used for resolution, ruining our evil plan)
        // Hence, we add it here, just for the C backend to see.

        if(realThisDecl) {
            // whoopsie-daisy
            body add(0, realThisDecl)
        }
        // as usual
        super(v)
        if(realThisDecl) {
            // there we go. nobody noticed.
            body removeAt(0)
        }
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
            }
        }

        return 0
    }

}




