import Type, Expression, Visitor, Node

import tinker/[Trail, Resolver, Response]

ArrayCreation: class extends Expression {

    expr: Expression = null /* assigned in ArrayAccess, RTFC */
    arrayType, realType : ArrayType

    init: func ~arrayCrea(=arrayType, .token) {
        super(token)
        realType = arrayType exprLessClone()
    }

    clone: func -> This {
        copy := new(arrayType, token)
        copy expr = expr ? expr clone() : null
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitArrayCreation(this)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        if(!arrayType resolve(trail, res) ok()) {
            return Response LOOP
        }

        if(!realType  resolve(trail, res) ok()) {
            return Response LOOP
        }

        return Response OK
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        if(oldie == arrayType) {
            oldie = kiddo as ArrayType
            return true
        }
        false
    }

    toString: func -> String {
        "%s new()" format(arrayType toString())
    }

    getType: func -> Type {
        realType
    }

}
