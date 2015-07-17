import ../frontend/Token
import FunctionDecl, Expression, Type, Visitor, Node, Argument, TypeDecl
import tinker/[Resolver, Response, Trail, Errors]

OperatorDecl: class extends Expression {

    _resolved := false

    symbol: String {
        get { symbol }
        set (s) {
            if (s == "implicit as") {
                symbol = "as"
                implicit = true
            } else {
                symbol = s
            }
        }
    }

    implicit := false // for implicit as

    fDecl : FunctionDecl { get set }

    init: func ~opDecl (=symbol, .token) {
        init(token)
    }

    init: func ~noSymbol (.token) {
        super(token)
        setFunctionDecl(FunctionDecl new("", token))
    }

    clone: func -> This {
        copy := new(symbol, token)
        copy fDecl = fDecl clone()
        copy
    }

    setFunctionDecl: func (=fDecl) {
        fDecl setInline(true)
        fDecl oDecl = this
    }
    getFunctionDecl: func -> FunctionDecl { fDecl }

    getSymbol: func -> String { symbol }

    accept: func (visitor: Visitor) { visitor visitFunctionDecl(fDecl) }

    getType: func -> Type { fDecl getType() }

    toString: func -> String {
        "operator " + symbol + " " + (fDecl ? fDecl getArgsRepr() : "")
    }

    setByRef: func (byref: Bool) {
        fDecl isThisRef = byref
    }

    setAbstract: func (abs: Bool) {
        fDecl setAbstract(abs)
    }

    /**
     * Called by AstBuilder on `onOperatorEnd`
     */
    computeName: func {
        assert(fDecl != null)

        sb := Buffer new()
        sb append("__op_"). append(getName())

        for(arg in fDecl args) {
            sb append("_"). append(arg instanceOf?(VarArg) ? "__varg__" : arg getType() toMangledString())
        }

        if(!fDecl isVoid()) {
            sb append("__"). append(fDecl getReturnType() toMangledString())
        }

        fDecl setName(sb toString())
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if (isResolved()) {
            return Response OK
        }

        match (resolveInsides(trail, res)) {
            case BranchResult BREAK => return Response OK
            case BranchResult LOOP  => return Response LOOP
        }

        match (checkImplicitConversions(trail, res)) {
            case BranchResult BREAK => return Response OK
            case BranchResult LOOP  => return Response LOOP
        }

        match (checkNumArgs(trail, res)) {
            case BranchResult BREAK => return Response OK
            case BranchResult LOOP  => return Response LOOP
        }

        _resolved = true

        Response OK
    }

    isResolved: func -> Bool {
        _resolved
    }

    /**
     * Resolve all children nodes of OperatorDecl
     */
    resolveInsides: func (trail: Trail, res: Resolver) -> BranchResult {
        fDecl resolve(trail, res)

        if (!fDecl isResolved()) {
            res wholeAgain(this, "need fDecl to be resolved")
            return BranchResult BREAK
        }

        BranchResult CONTINUE
    }

    _numArgsDone := false

    /**
     * Check that this operator overload has the right number of arguments
     */
    checkNumArgs: func (trail: Trail, res: Resolver) -> BranchResult {
        if (_numArgsDone) {
            // all done
            return BranchResult CONTINUE
        }

        numArgs := fDecl args size
        if (fDecl owner) {
            numArgs += 1
        }

        match symbol {
            // unary only
            case "as" =>
                if (numArgs != 1) {
                    return needArgs(res, "exactly 1", numArgs)
                }

            // unary or binary
            case "-" || "+" =>
                if (numArgs < 1 || numArgs > 2) {
                    return needArgs(res, "1 or 2", numArgs)
                }

            // only case of 3-arguments only
            case "[]=" =>
                if (numArgs != 3) {
                    return needArgs(res, "exactly 3", numArgs)
                }

            // all remaining operators are binary
            case =>
                if (numArgs != 2) {
                    return needArgs(res, "exactly 2", numArgs)
                }
        }
        
        _numArgsDone = true
        BranchResult CONTINUE
    }

    _doneImplicit := false

    /**
     * Handles 'implicit as' (adds to a list in the relevant
     * TypeDecl)
     */
    checkImplicitConversions: func (trail: Trail, res: Resolver) -> BranchResult {
        if (_doneImplicit) {
            // already done
            return BranchResult CONTINUE
        }

        if (!implicit) {
            // nothing to do
            _doneImplicit = true
            return BranchResult CONTINUE
        }

        fromType := fDecl args get(0) getType()

        if(fromType == null || !fromType isResolved()) {
            res wholeAgain(this, "need first arg's type")
            return BranchResult BREAK
        }

        match (fromType getRef()) {
            case td: TypeDecl =>
                // mark as an implicit conversion for that type
                td implicitConversions add(this)
        }

        _doneImplicit = true
        BranchResult CONTINUE
    }

    /**
     * Called when wrong number of args given to operator overload
     */
    needArgs: func (res: Resolver, expected: String, given: Int) -> BranchResult {
        message := "Overloading of '#{symbol}' requires #{expected} argument(s), not #{given}."
        err := InvalidOperatorOverload new(token, message)
        res throwError(err)

        BranchResult BREAK
    }

    /**
     * Get the name of the overload based on our symbol
     */
    getName: func -> String {
        return match (symbol) {
            case "[]"  =>  "idx"
            case "+"   =>  "add"
            case "-"   =>  "sub"
            case "*"   =>  "mul"
            case "**"  =>  "exp"
            case "/"   =>  "div"
            case "<<"  =>  "blsh"
            case ">>"  =>  "blsh"
            case "^"   =>  "bxor"
            case "&"   =>  "band"
            case "|"   =>  "bor"

            case "[]=" =>  "idxa"
            case "+="  =>  "adda"
            case "-="  =>  "suba"
            case "*="  =>  "mula"
            case "**=" =>  "expa"
            case "/="  =>  "diva"
            case "<<=" =>  "blsha"
            case ">>=" =>  "blsha"
            case "^="  =>  "bxora"
            case "&="  =>  "banda"
            case "|="  =>  "bora"

            case "=>"  =>  "dar"
            case "&&"  =>  "land"
            case "||"  =>  "lor"
            case "%"   =>  "mod"
            case "="   =>  "ass"
            case "=="  =>  "eq"
            case "<="  =>  "gte"
            case ">="  =>  "lte"
            case "!="  =>  "ne"
            case "!"   =>  "not"
            case "<"   =>  "lt"
            case ">"   =>  "gt"
            case "<=>" =>  "cmp"
            case "~"   =>  "b_neg"
            case "as"  =>  "as"

            case "??"  => "coal"

            case =>
                handler := token module params errorHandler
                err := InvalidOperatorOverload new(token, "Unknown overloaded symbol: %s" format(symbol))
                handler onError(err)
                "unk"
        }
    }

    replace: func (oldie, kiddo: Node) -> Bool { false }

    isScope: func -> Bool { true }

}

InvalidOperatorOverload: class extends Error {
    init: super func ~tokenMessage
}


OverloadStatus: enum {
    TRYAGAIN // operator usage waiting for something else to resolve
    REPLACED // operator usage was replaced with a call to an overload
    NONE     // operator usage fully resolved, no overload in sight
}

