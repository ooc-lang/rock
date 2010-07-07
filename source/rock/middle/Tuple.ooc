import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, Expression, Node
import tinker/[Response, Resolver, Trail]
import structs/[List, ArrayList]
import text/Buffer

Tuple: class extends Expression {

    unwrapped := false
    elements := ArrayList<Expression> new()

    init: func ~arrayLiteral (.token) {
        super(token)
    }

    getElements: func -> List<Expression> { elements }

    accept: func (visitor: Visitor) {
        token throwError("Visiting a Tuple! That shouldn't happen.")
    }
    getType: func -> Type { null }

    toString: func -> String {
        if(elements isEmpty()) return "()"

        buffer := Buffer new()
        buffer append('(')
        isFirst := true
        for(element in elements) {
            if(isFirst) isFirst = false
            else        buffer append(", ")
            buffer append(element toString())
        }
        buffer append(')')
        buffer toString()
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        token throwError("Hey! got a tuple right there o/")

        Responses OK
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        elements replace(oldie as Expression, kiddo as Expression)
    }

}