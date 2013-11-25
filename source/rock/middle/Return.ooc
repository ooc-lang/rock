import structs/List
import ../frontend/[Token,BuildParams]
import Visitor, Statement, Expression, Node, FunctionDecl, FunctionCall,
       VariableAccess, VariableDecl, AddressOf, ArrayAccess, If,
       BinaryOp, Cast, Type, TypeList, Module, Tuple
import tinker/[Response, Resolver, Trail, Errors]

Return: class extends Statement {

    expr: Expression = null
    label: String = null // if non-null, written as a 'goto label' instead of 'return'. Useful in inlines.

    init: func ~ret (.token) {
        init(null, token)
    }

    init: func ~retWithExpr (=expr, .token) {
        super(token)
    }

    clone: func -> This {
        new(expr ? expr clone() : null, token)
    }

    accept: func (visitor: Visitor) { visitor visitReturn(this) }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        retType: Type = null
        returnArgs: List<VariableDecl> = null

        {
            idx := trail find(FunctionDecl)
            if(idx != -1) {
                // Found a function decl! It's the regular case: we're all set.
                fDecl := trail get(idx, FunctionDecl)

                if(expr) fDecl inferredReturnType = expr getType()

                retType = fDecl getReturnType()
                returnArgs = fDecl getReturnArgs()
            }
        }

        if (!retType || !retType isResolved()) {
            res wholeAgain(this, "need returnType to be resolved!")
            return Response OK
        }

        if(expr) {
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                return response
            }

            if(expr getType() == null || !expr getType() isResolved()) {
                res wholeAgain(this, "expr type is unresolved")
                return Response OK
            }
        }

        // by this point, retType is non-null *and* resolved
        retType = retType refToPointer()

        shouldHaveReturnArgs := (retType isGeneric() || retType instanceOf?(TypeList))
        if (shouldHaveReturnArgs && returnArgs empty?()) {
            res wholeAgain(this, "waiting for fDecl to create returnArgs")
        }

        isVoid := retType void?

        if(expr) {
            if(expr getType() == null || !expr getType() isResolved()) {
                res wholeAgain(this, "Need info about the expr type")
                return Response OK
            }

            // generic returns, multi-returns
            if(!returnArgs empty?()) {
                replaced := handleReturnArgs(retType, returnArgs, res, trail)
                if (replaced) {
                    return Response OK
                }
            }

            // check: func is void yet we return something
            if (isVoid) {
                err := InconsistentReturn new(expr token, "Returning something from a void function is illegal")
                res throwError(err)
            }

            // check: func isn't void but we return the wrong thing
            if(!isVoid && !retType equals?(expr getType())) {
                score := expr getType() getScore(retType)
                if (score == -1) {
                    res wholeAgain(this, "something's unresolved in declared ret type vs returned type.")
                    return Response OK
                }

                if (score < 0) {
                    msg: String
                    if (res params veryVerbose) {
                        msg = "The declared return type (%s) and the returned value (%s) do not match!\nscore = %d\ntrail = %s" format(retType toString(), expr getType() toString(), score, trail toString())
                    } else {
                        msg = "The declared return type (%s) and the returned value (%s) do not match!" format(retType toString(), expr getType() toString())
                    }
                    res throwError(InconsistentReturn new(token, msg))
                }
                expr = Cast new(expr, retType, expr token)
            }
        } else {
            // check: func is non-void and we're returning nothing
            if (!isVoid && returnArgs empty?()) {
                msg := "Returning nothing is non-void function"
                err := InconsistentReturn new(token, msg)
                res throwError(err)
            }
        }

        return Response OK

    }

    handleReturnArgs: func (retType: Type, returnArgs: List<VariableDecl>, res: Resolver, trail: Trail) -> Bool {
        // if it's a generic FunctionCall, just hook its returnArg to the outer FunctionDecl and be done with it.
        if(expr && expr instanceOf?(FunctionCall)) {
            fCall := expr as FunctionCall
            ref := fCall getRef()

            if(ref == null) {
                res wholeAgain(this, "Return needs its expr (fcall) to be resolved")
                return false
            }

            fRetType := ref getReturnType()
            if (fRetType == null || !fRetType isResolved()) {
                res wholeAgain(this, "We need the fcall to be fully resolved before resolving ourselves")
                return false
            }

            if (fRetType isGeneric()) {
                // TODO: what if the return type of the outer function decl isn't generic?
                fCall setReturnArg(VariableAccess new(returnArgs[0], token))
                if(!trail peek() addBefore(this, fCall)) {
                    err := CouldntAddBefore new(token, this, fCall, trail)
                    res throwError(err)
                }
                expr = null
                res wholeAgain(this, "Unwrapped into outer fCall")
                return true
            }

            match fRetType {
                // outer is a multi-return? Us too! Just relay them.
                case tl: TypeList =>
                    callReturnArgs := fCall getReturnArgs()
                    for (returnArg in returnArgs) {
                        vAcc := VariableAccess new(returnArg, returnArg token)
                        callReturnArgs add(vAcc)
                    }
                    if(!trail peek() addBefore(this, fCall)) {
                        err := CouldntAddBefore new(token, this, fCall, trail)
                        res throwError(err)
                    }
                    expr = null
                    res wholeAgain(this, "Unwrapped into outer fCall")
                    return true
            }
        }

        // if the expr is something else, we're gonna have to handle it ourselves. muahaha.
        j := 0
        for(returnArg in returnArgs) {
            returnExpr := expr
            if(expr instanceOf?(Tuple)) {
                returnExpr = expr as Tuple elements get(j)
            }

            returnAcc := VariableAccess new(returnArg, token)

            byRef? := returnArg getType() instanceOf?(ReferenceType)
            needIf? := (retType isGeneric() || byRef?)

            if(needIf?) {
                // generic variables have weird semantics
                if1 := If new(byRef? ? AddressOf new(returnAcc, token) : returnAcc, token)

                if(returnExpr hasSideEffects()) {
                    vdfe := VariableDecl new(null, generateTempName("returnVal"), returnExpr, returnExpr token)
                    if(!trail peek() addBefore(this, vdfe)) {
                        res throwError(CouldntAddBefore new(token, this, vdfe, trail))
                    }
                    returnExpr = VariableAccess new(vdfe, vdfe token)
                }

                // ass needs to be created now because returnExpr might've changed
                ass := BinaryOp new(returnAcc, returnExpr, OpType ass, token)
                if1 getBody() add(ass)

                if(!trail peek() addBefore(this, if1)) {
                    res throwError(CouldntAddBefore new(token, this, if1, trail))
                }
            } else {
                ass := BinaryOp new(returnAcc, returnExpr, OpType ass, token)
                if(!trail peek() addBefore(this, ass)) {
                    res throwError(CouldntAddBefore new(token, this, ass, trail))
                }
            }
            j += 1

        }

        expr = null
        res wholeAgain(this, "Turned into an assignment")
        return true
    }

    toString: func -> String { expr == null ? "return" : "return " + expr toString() }

    replace: func (oldie, kiddo: Node) -> Bool {
        if(expr == oldie) {
            expr = kiddo
            return true
        }

        return false
    }

}

InconsistentReturn: class extends Error {
    init: super func ~tokenMessage
}

