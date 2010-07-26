import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, Expression, Node, TypeList, NullLiteral,
       Cast, StructLiteral
import tinker/[Response, Resolver, Trail, Errors]
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
        token formatMessage("Visiting a Tuple! We're on the good track.", "INFO") println()
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
        if(elements empty?()) return "()"

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
        trail push(this)
        for (element in elements) {
            response := element resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return Responses LOOP
            }
        }

        if(getType()) {
            getType() resolve(trail, res)
        } else {
            res wholeAgain(this, "Need type")
        }
        trail pop(this)

        parent := trail peek()
        if(parent instanceOf?(Cast)) {
            cast := parent as Cast
            structLit := StructLiteral new(cast getType(), elements, token)
            grandpa := trail peek(2)
            if(!grandpa replace(cast, structLit)) {
                res throwError(CouldntReplace new(token, cast, structLit, trail))
            }
        }

        Responses OK
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        elements replace(oldie as Expression, kiddo as Expression)
    }

}