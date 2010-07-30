import ../frontend/[Token,BuildParams]
import Visitor, Statement, Expression, Node, FunctionDecl, FunctionCall,
       VariableAccess, VariableDecl, AddressOf, ArrayAccess, If,
       BinaryOp, Cast, Type, Module, Tuple
import tinker/[Response, Resolver, Trail, Errors]

Return: class extends Statement {

    expr: Expression = null

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

        idx := trail find(FunctionDecl)
        fDecl: FunctionDecl = null
        retType: Type = null
        if(idx != -1) {
            fDecl = trail get(idx) as FunctionDecl

            if(expr) fDecl inferredReturnType = expr getType()

            retType = fDecl getReturnType()
            if (!retType isResolved()) {
                return Responses LOOP
            }
        }

        if(!expr) {
            if (fDecl getReturnArgs() empty?() && retType != voidType) {
                res throwError(InconsistentReturn new(token, "Function is not declared to return `null`! trail = %s" format(trail toString())))
            } else {
                return Responses OK
            }
        }

        {
            trail push(this)
            response := expr resolve(trail, res)
            trail pop(this)
            if(!response ok()) {
                return response
            }

            if(expr getType() == null || !expr getType() isResolved()) {
                res wholeAgain(this, "expr type is unresolved"); return Responses OK
            }
        }

        if (retType) {

            retType = retType refToPointer()

            if(retType isGeneric() && fDecl getReturnArgs() empty?()) {
                fDecl getReturnArg() // create the generic returnArg - just in case.
            }

            if(!fDecl getReturnArgs() empty?()) {

                // if it's a generic FunctionCall, just hook its returnArg to the outer FunctionDecl and be done with it.
                if(expr instanceOf?(FunctionCall)) {
                    fCall := expr as FunctionCall
                    if( fCall getRef() == null ||
                        fCall getRef() getReturnType() == null ||
                       !fCall getRef() getReturnType() isResolved()) {
                        res wholeAgain(this, "We need the fcall to be fully resolved before resolving ourselves")
                    }
                    if(fCall getRef() getReturnType() isGeneric()) {
                        // TODO: what if the return type of the outer fDecl isn't generic?
                        fCall setReturnArg(VariableAccess new(fDecl getReturnArg(), token))
                        if(!trail peek() addBefore(this, fCall)) {
                            res throwError(CouldntAddBefore new(token, this, fCall, trail))
                        }
                        expr = null
                        res wholeAgain(this, "Unwrapped into outer fCall")
                        return Responses OK
                    }
                }

                // if the expr is something else, we're gonna have to handle it ourselves. muahaha.
                j := 0
                for(returnArg in fDecl getReturnArgs()) {

                    returnExpr := expr
                    if(expr instanceOf?(Tuple)) {
                        returnExpr = expr as Tuple elements get(j)
                    }

                    returnAcc := VariableAccess new(returnArg, token)

                    // why take the address? well if the returnArgs aren't generic, then they are ReferenceTypes
                    // to check if we care about a returnArg, we need to know if the *address* of the passed pointer is non-null,
                    // not the value itself. So we take AddressOf.
                    if1 := If new(retType isGeneric() ? returnAcc : AddressOf new(returnAcc, token), token)

                    if(returnExpr hasSideEffects()) {
                        vdfe := VariableDecl new(null, generateTempName("returnVal"), returnExpr, returnExpr token)
                        if(!trail peek() addBefore(this, vdfe)) {
                            res throwError(CouldntAddBefore new(token, this, vdfe, trail))
                        }
                        returnExpr = VariableAccess new(vdfe, vdfe token)
                    }

                    ass := BinaryOp new(returnAcc, returnExpr, OpType ass, token)
                    if1 getBody() add(ass)

                    if(!trail peek() addBefore(this, if1)) {
                        res throwError(CouldntAddBefore new(token, this, if1, trail))
                    }
                    j += 1

                }

                expr = null
                res wholeAgain(this, "Turned into an assignment")
                //return Responses OK
                return Responses LOOP

            }

            if(expr) {
                if(expr getType() == null || !expr getType() isResolved()) {
                    res wholeAgain(this, "Need info about the expr type")
                    return Responses OK
                }
                if(!retType getName() toLower() equals?("void") && !retType equals?(expr getType())) {
                    score := expr getType() getScore(retType)
                    if (score == -1) {
                        res wholeAgain(this, "something's unresolved in declared ret type vs returned type.")
                        return Responses OK
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

        return Responses OK

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

