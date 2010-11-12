
import structs/[ArrayList, HashMap]
import ../frontend/Token
import ../io/TabbedWriter
import Block, VariableAccess, FunctionCall, Cast, VariableDecl, TypeDecl,
       BaseType, Visitor, Node, FunctionDecl, Type
import algo/autoReturn

import tinker/[Trail, Resolver, Response]

// FIXME: highly experimental. Don't touch under death penalty.

InlineContext: class extends Block {

    returnType : Type
    returnArgs := ArrayList<VariableDecl> new()

    fCall: FunctionCall
    ref: FunctionDecl

    casted := HashMap<VariableDecl, VariableDecl> new()

    thisDecl = null, realThisDecl = null : VariableDecl

    label: String

    init: func (=fCall, .token) {
        super(token)

        // Store the ref on our own, just in case
        ref = fCall ref

        // figure out a label
        label = generateTempName("blackhole")

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

        "== Inline context of %s's ref has %d, and fCall has %d! ==" format(toString(), fCall ref getReturnArgs() getSize(), fCall getReturnArgs() getSize()) println()
        returnType = ref returnType realTypize(fCall)
        "Return type of ref is %s, ours is %s" format(ref returnType toString(), returnType toString()) println()

    }

    accept: func (v: Visitor) {
        // here we play a little trick on our backend:
        // the real this decl has to be written if we're a member call,
        // because, you know, otherwise this can't be accessed.
        // but since we have been using a fake 'this' to intercept
        // variable access resolution, we weren't able to simply add
        // it to the body during the resolution phase (the real 'this'
        // would've been used for resolution, ruining our evil plan)
        // Hence, we add it here, just for the backend to see.

        hasThis? := (fCall expr != null &&
                     fCall expr instanceOf?(VariableAccess) &&
                     fCall expr as VariableAccess getName() == "this"
                    )

        if(!hasThis? && realThisDecl != null) {
            // whoopsie-daisy
            body add(0, realThisDecl)
        }

        // as usual
        super(v)

        if(!hasThis? && realThisDecl != null) {
            // there we go. nobody noticed.
            body removeAt(0)
        }
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        if(realThisDecl) {
            if(!realThisDecl resolve(trail, res) ok()) return Response OK
        }

        response := super(trail, res)
        if(!response ok()) {
            return response
        }

        autoReturn(trail, res, this, body, returnType)
    }

    resolveCall: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        "====================================" println()
        "In inline context of %s, looking for call %s" format(fCall toString(), call toString()) println()

        "fCall expr = %s" format(fCall expr ? fCall expr toString() : "<null>") println()
        if(fCall expr != null) {
            exprType := fCall expr getType()
            if(exprType != null && exprType getRef() != null) {
                ref := exprType getRef()
                "ref is %s (%p) and it's a %s" format(ref toString(), ref, ref class name) println()

                proxy := FunctionCall new(call getName(), call token)
                proxy args addAll(call args)
                proxy expr = fCall expr
                ref as TypeDecl getMeta() resolveCall(proxy, res, trail)
                if(proxy ref != null) {
                    "resolved to %s (vDecl = %s, proxy expr = %s)" format(proxy ref toString(), proxy ref vDecl ? proxy ref vDecl toString() : "(nil)", proxy expr ? proxy expr toString() : "(nil)") println()
                    oldExpr := call expr
                    call expr = proxy expr
                    if(call suggest(proxy ref, res, trail)) {
                        "Congratulations soldier - we now have call %s, with expr %s" format(call toString(), call expr ? call expr toString() : "(nil)") println()
                        return 0
                    } else {
                        // restore
                        call expr = oldExpr
                    }
                }
            }
        }

        super(call, res, trail)
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        "====================================" println()
        "In inline context of %s, looking for access %s" format(fCall toString(), access toString()) println()

        if(fCall expr != null) {
            exprType := fCall expr getType()
            if(exprType != null && exprType getRef() != null) {
                ref := exprType getRef()
                "ref is %s" format(ref toString()) println()

                if(access getName() == "this") {
                    if(access suggest(thisDecl)) {
                        "We did it, honey!" println()
                        return 0
                    }
                }

                proxy := access clone() as VariableAccess
                ref resolveAccess(proxy, res, trail)
                if(proxy ref != null) {
                    "resolved to %s" format(proxy ref toString()) println()
                    targetType := proxy ref getType()
                    realType := targetType realTypize(fCall)

                    suggestion : VariableDecl = null
                    adjustExpr? := false

                    if(targetType equals?(realType)) {
                        "Equal types! suggesting %s" format(proxy ref toString()) println()
                        suggestion = proxy ref
                        adjustExpr? = true
                    } else {
                        "Casting! targetType = %s, realType = %s" format(targetType toString(), realType toString()) println()
                        realtypized := VariableDecl new(null, proxy getName(), Cast new(proxy, realType, proxy ref token), proxy ref token)
                        realtypized owner = fCall ref owner

                        varAcc := VariableAccess new("this", nullToken)
                        varAcc ref = realThisDecl
                        proxy expr = varAcc

                        casted put(proxy ref as VariableDecl, realtypized) // TODO: use that later, in case of multiple access
                        // 1 = after this :) hackhackhack!
                        body add(1, realtypized)
                        suggestion = realtypized
                    }
                    if(suggestion != null && access suggest(suggestion)) {
                        " - Suggestion worked o/" println()
                        if(suggestion owner != null && adjustExpr?) {
                            "Ooh, owner of %s isn't null. Setting expr :D" format(suggestion toString()) println()
                            thisAcc := VariableAccess new("this", token)
                            thisAcc ref = realThisDecl
                            access expr = thisAcc
                        }
                        return 0
                    }
                }
            }
        }

        super(access, res, trail)
    }

    resolveType: func (type: Type, res: Resolver, trail: Trail) -> Int {
        "====================================" println()
        "In inline context of %s, looking for type %s" format(fCall toString(), type toString()) println()

        real := type realTypize(fCall)
        if(real != null) {
            "found real type %s" format(real toString()) println()
            if(type instanceOf?(BaseType) && real instanceOf?(BaseType)) {
                type as BaseType name = real getName()
                type setRef(real getRef())
            }
        }

        super(type, res, trail)
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
        "In inlined type %s, looking for access %s" format(toString(), access toString()) println()

        if(access expr instanceOf?(VariableAccess)) {
            varAcc := access expr as VariableAccess
            if(varAcc getName() == "this") {
                access expr = null // mwahahaha.
                context resolveAccess(access, res, trail)
            }
        }

        0
    }

    resolveCall: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        if(context fCall expr) {
            ref := context fCall expr getType() getRef()
            if(ref) {
                "in InlinedType resolveCall, ref is %s and it's a %s" format(ref toString(), ref class name) println()
                return ref resolveCall(call, res, trail)
            }
        }

        0
    }

}




