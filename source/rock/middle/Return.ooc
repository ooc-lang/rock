import structs/List
import ../frontend/[Token,BuildParams]
import Visitor, Statement, Expression, Node, FunctionDecl, FunctionCall,
       VariableAccess, VariableDecl, AddressOf, ArrayAccess, If,
       BinaryOp, Cast, Type, Module, Tuple, InlineContext
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

        /*
         * This part used to be simpler, before inlining came to life.
         * When inlining, we might have to deal with an InlineContext
         * instead of a FunctionDecl.
         *
         * Hence, we only attempt to get 1) a return type 2) return args
         */

        retType: Type = null
        returnArgs: List<VariableDecl> = null

        {
            // Do we have an inline context? we have to be careful if yes.
            idx := trail find(InlineContext)
            if(idx != -1) {
                // Yes we do. Take the return type and return args from here, then.
                ctx := trail get(idx, InlineContext)

                retType = ctx returnType
                returnArgs = ctx returnArgs
                label = ctx label
            } else {
                idx = trail find(FunctionDecl)
                if(idx != -1) {
                    // Found a function decl! It's the regular case: we're all set.
                    fDecl := trail get(idx, FunctionDecl)

                    if(expr) fDecl inferredReturnType = expr getType()

                    retType = fDecl getReturnType()
                    returnArgs = fDecl getReturnArgs()
                }
            }
        }

        if (retType && !retType isResolved()) {
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
                res wholeAgain(this, "expr type is unresolved"); return Response OK
            }
        } else {
            if (returnArgs empty?() && !retType void?) {
                res throwError(InconsistentReturn new(token, "Can't return nothing in function declared as returning a %s" format(retType toString())))
            } else {
                // no expression, and the function's alright with that - nothing more to do.
                return Response OK
            }
        }

        if (retType) {

            retType = retType refToPointer()

            if(retType isGeneric() && returnArgs empty?()) {
                // create the generic returnArg - just in case.
                returnArgs add(VariableDecl new(retType, generateTempName("genericReturn"), token))
            }

            if(!returnArgs empty?()) {

                // if it's a generic FunctionCall, just hook its returnArg to the outer FunctionDecl and be done with it.
                if(expr instanceOf?(FunctionCall)) {
                    fCall := expr as FunctionCall
                    if( fCall getRef() == null ||
                        fCall getRef() getReturnType() == null ||
                       !fCall getRef() getReturnType() isResolved()) {
                        res wholeAgain(this, "We need the fcall to be fully resolved before resolving ourselves")
                    }

                    if(fCall getRef() getReturnType() isGeneric()) {
                        // TODO: what if the return type of the outer function decl isn't generic?
                        fCall setReturnArg(VariableAccess new(returnArgs[0], token))
                        if(!trail peek() addBefore(this, fCall)) {
                            res throwError(CouldntAddBefore new(token, this, fCall, trail))
                        }
                        expr = null
                        res wholeAgain(this, "Unwrapped into outer fCall")
                        return Response OK
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
                return Response LOOP

            }

            if(expr) {
                if(expr getType() == null || !expr getType() isResolved()) {
                    res wholeAgain(this, "Need info about the expr type")
                    return Response OK
                }
                if(!retType getName() toLower() equals?("void") && !retType equals?(expr getType())) {
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
            }

            if (retType == voidType && !expr)
                res throwError(InconsistentReturn new(expr token, "Function is declared to return `null`, not %s! trail = %s" format(expr getType() toString(), trail toString())))
        }

        return Response OK

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

