import ../frontend/Token
import [Type, Expression, VariableAccess, Comparison, Ternary, VariableDecl, CommaSequence, BinaryOp,
        NullLiteral, Visitor, Node]

import tinker/[Resolver, Response, Trail, Errors]
import structs/ArrayList

SafeNavigation: class extends Expression {
    expr: Expression
    idents := ArrayList<String> new()

    _resolved? := false

    init: func (=expr, token: Token) {
        super(token)
    }

    // We replace ourselves, no need to return any type
    getType: func -> Type { null }

    clone: func -> This {
        other := This new(expr clone(), token)
        other idents = idents clone()
        other
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        if (_resolved?) return Response OK

        trail push(this)
        resp := expr resolve(trail, res)
        if (!resp ok()) {
            trail pop(this)
            return resp
        }
        trail pop(this)

        if (!expr getType()) {
            res wholeAgain(this, "need type of safe navigation access expression")
            return Response OK
        }

        // We need to avoid multiple evaluation of the expression, so we will use a variable declaration and assign it in a comma list before this
        vDecl := VariableDecl new(expr getType(), generateTempName("safeNavExpr"), token)
        vAccess := VariableAccess new(vDecl, token)

        if (!trail addBeforeInScope(this, vDecl)) {
            res throwError(CouldntAddBeforeInScope new(token, this, vDecl, trail))
            return Response OK
        }

        seq := CommaSequence new(token)
        assignment := BinaryOp new(vAccess, expr, OpType ass, token)

        seq add(assignment)

        // If we have 'expr $ a $ b $ c', our list is now [expr a, expr a b, expr a b c]
        vas := ArrayList<VariableAccess> new(idents size)
        for ((index, ident) in idents) {
            if (index == 0) {
                vas add(VariableAccess new(vAccess, ident, token))
            } else {
                vas add(VariableAccess new(vas last(), ident, token))
            }
        }

        localNull := NullLiteral new(token)

        makeNotEquals := func(e: Expression) -> Comparison {
            Comparison new(e, localNull, CompType notEqual, token)
        }

        makeTernary := func(cond: Comparison, e: Expression) -> Ternary {
            Ternary new(cond, e, localNull, token)
        }

        curr : Ternary = null
        iterator := vas backIterator()

        while (iterator hasPrev?()) {
            access := iterator prev()

            curr = match curr {
                case null => makeTernary(makeNotEquals(access), access)
                case      => makeTernary(makeNotEquals(access), curr)
            }
        }

        curr = makeTernary(makeNotEquals(vAccess), curr)

        seq add(curr)

        if (!trail peek() replace(this, seq)) {
            res throwError(CouldntReplace new(token, this, seq, trail))
            return Response OK
        }

        _resolved? = true

        res wholeAgain(this, "replaced safe navigation access with comma sequence")
        Response OK
    }

    toString: func -> String {
        buff := Buffer new()
        buff append(expr toString())

        for (i in idents) {
            buff append(" $ ") . append(i)
        }

        buff toString()
    }

    accept: func(visitor: Visitor)

    replace: func(oldie: Node, kiddo: Node) -> Bool {
        match oldie {
            case e: Expression =>
                if (e == expr) {
                    expr = kiddo as Expression
                    return true
                }
        }

        false
    }

    isResolved: func -> Bool {
        _resolved?
    }
}
