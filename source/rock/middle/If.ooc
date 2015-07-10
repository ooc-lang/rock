import ../frontend/Token
import Conditional, Expression, Visitor, Else
import tinker/[Trail, Resolver, Response, Errors]

If: class extends Conditional {
    elze: Else
    unwrapped: Bool = false

    init: func ~_if (.condition, .token) { super(condition, token) }

    setElse: func(=elze)
    getElse: func -> Else { elze }

    clone: func -> This {
        copy := new(condition ? condition clone() : null, token)
        body list each(|e| copy body add(e clone()))
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitIf(this)
    }

    toString: func -> String {
        "if (" + condition toString() + ")" + body toString()
    }

    isDeadEnd: func -> Bool { false }

    resolve: func(trail: Trail, res: Resolver) -> Response {
        if(elze != null && !unwrapped){
            trail push(this)
            if(!trail addAfterInScope(this, elze)){
                trail pop(this)
                res throwError(FailedUnwrapElse new(elze token, "Failed to unwrap else"))
            }
            unwrapped = true
            elze resolve(trail, res)
            trail pop(this)
            res wholeAgain(this, "just unwrapped else")
            return Response OK
        }

        super(trail, res)
    }

}

FailedUnwrapElse: class extends Error{
   init: super func ~tokenMessage
}
