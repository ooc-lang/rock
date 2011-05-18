import ../frontend/Token
import Literal, Expression, Visitor, Type, Node, BaseType, Foreach,
       FunctionCall, VariableAccess
import tinker/[Resolver, Response, Trail]

RangeLiteral: class extends Literal {

    lower, upper: Expression
    type := static BaseType new("Range", nullToken)

    init: func ~rangeLiteral (=lower, =upper, .token) {
        super(token)
    }

    clone: func -> This {
        new(lower clone(), upper clone(), token)
    }

    accept: func (visitor: Visitor) {
        visitor visitRangeLiteral(this)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        {
            response := super(trail, res)
            if(!response ok()) return response
        }

        trail push(this)

        {
            response := lower resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        {
            response := upper resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        trail pop(this)

        parent := trail peek() as Node
        if(!parent instanceOf?(Foreach)) {
            newCall := FunctionCall new(VariableAccess new("Range", token), "new", token)
            newCall args add(lower) .add(upper)

            if(!parent replace(this, newCall)) {
                "Couldn't replace %s with %s in %s" printfln(toString(), newCall toString(), parent toString())
            }
            res wholeAgain(this, "replaced with range constructor!")
        }

        return Response OK
    }

    getType: func -> Type { type }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case lower => lower = kiddo; true
            case upper => upper = kiddo; true
            case => false
        }
    }

}
