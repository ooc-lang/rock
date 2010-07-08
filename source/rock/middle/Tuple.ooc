import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, Expression, Node, TypeList, NullLiteral
import tinker/[Response, Resolver, Trail]
import structs/[List, ArrayList]
import text/Buffer

Tuple: class extends Expression {

    elements := ArrayList<Expression> new()
    type : Type = null

    init: func ~arrayLiteral (.token) {
        super(token)
    }

    getElements: func -> List<Expression> { elements }

    accept: func (visitor: Visitor) {
        token printMessage("Visiting a Tuple! We're on the good track.", "INFO")
        NullLiteral new(token) accept(visitor)
    }

    getType: func -> Type {
        // TODO: what if we modify the tuple in the AST later?
        if(!type) {
            list := TypeList new(token)
            for(element in elements) {
                // TODO: what if the types are null?
                list types add(element getType())
            }
            type = list
        }
        type
    }

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
        getType() resolve(trail, res)
        token printMessage("Hey! got a tuple right there o/ Parent is a %s. Doing nothing." format(trail peek() toString()), "INFO")

        Responses OK
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        elements replace(oldie as Expression, kiddo as Expression)
    }

}