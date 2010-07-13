import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, Expression, Node, TypeList, NullLiteral,
       Cast, StructLiteral
import tinker/[Response, Resolver, Trail]
import structs/[List, ArrayList]
import text/Buffer

Tuple: class extends Expression {

    elements := ArrayList<Expression> new()
    type : Type = null

    init: func ~tuple (.token) {
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
                elementType := element getType()
                if(elementType) {
                    list types add(elementType)
                } else {
                    return null
                }
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
        for (element in elements) {
            if(!element resolve(trail, res) ok()) return Responses LOOP
        }

        if(getType()) {
            getType() resolve(trail, res)
        } else {
            res wholeAgain(this, "Need type")
        }

        parent := trail peek()
        if(parent instanceOf(Cast)) {
            cast := parent as Cast
            structLit := StructLiteral new(cast getType(), elements, token)
            grandpa := trail peek(2)
            if(!grandpa replace(cast, structLit)) {
                token throwError("Couldn't replace %s with %s :x trail = %s" format(cast toString(), structLit toString(), trail toString()))
            }
        }

        token printMessage("Hey! got a tuple right there o/ Parent is a %s. Doing nothing." format(parent toString()), "INFO")

        Responses OK
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        elements replace(oldie as Expression, kiddo as Expression)
    }

}