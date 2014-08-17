import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, Expression, Node, TypeList, NullLiteral,
       Cast, StructLiteral, VariableAccess
import tinker/[Response, Resolver, Trail, Errors]
import structs/[List, ArrayList]

Tuple: class extends Expression {

    elements := ArrayList<Expression> new()
    type : Type = null

    init: func ~tuple (.token) {
        super(token)
    }

    clone: func -> This {
        copy := new(token)
        copy type = type ? type clone() : null
        elements each(|e|
            copy elements add(e clone())
        )
        copy
    }

    getElements: func -> List<Expression> { elements }

    get: func (i: Int) -> Expression { elements[i] }

    operator [] (i: Int) -> Expression { get(i) }

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
                    good := false

                    // if it's a varacc to '_' it's fine
                    match element {
                        case vAcc: VariableAccess =>
                            if (vAcc getName() == "_") {
                                good = true
                                list types add(voidType)
                            }
                    }

                    if (!good) {
                        return null
                    }
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
                return Response LOOP
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

        Response OK
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        elements replace(oldie as Expression, kiddo as Expression)
    }

}

InvalidTupleUse: class extends Error {
    init: super func ~tokenMessage
}

