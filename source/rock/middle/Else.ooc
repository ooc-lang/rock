import ../frontend/Token
import Conditional, Expression, If, Node, Scope, Statement, Visitor
import tinker/[Errors, Resolver, Response, Trail]

Else: class extends Conditional {

    init: func ~_else (.token) { super(null, token) }

    clone: func -> This {
        copy := new(token)
        body list each(|e| copy body add(e clone()))
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitElse(this)
    }

    toString: func -> String {
        "else " + body toString()
    }

    resolve: func(trail: Trail, res: Resolver) -> Response {
        trail push(this)
        response := body resolve(trail, res)
        trail pop(this)
        return response
    }

}
