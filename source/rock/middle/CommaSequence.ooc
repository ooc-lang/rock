import structs/[List, ArrayList]
import ../frontend/Token
import Expression, Visitor, Type, Node, VariableDecl, FunctionDecl, Statement
import tinker/[Trail, Resolver, Response]

CommaSequence: class extends Expression {

    body := ArrayList<Statement> new()
    allResolved := false

    origin: Node

    init: func ~commaSeq (.token) {
        super(token)
    }

    add: func (n: Node) {
        body add(n as Statement)
    }

    clone: func -> Node {
        // let stuff unwrap again if we're cloned
        if (origin) {
            return origin clone()
        }

        copy := new(token)
        for (stat in body) {
            copy body add(stat clone())
        }
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitCommaSequence(this)
    }

    getType: func -> Type { body empty?() ? null : body last() as Expression getType() }

    toString: func -> String {
        buf := Buffer new()
        buf append("<CommaSequence>(")
        first := true
        for (s in body) {
            if (first) {
                first = false
            } else {
                buf append(", ")
            }
            buf append(s toString())
        }
        buf append(")")
        return buf toString()
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)
        allGood := true
        for (statement in body) {
            response := statement resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
            if (!statement isResolved()) {
                allGood = false
            }
        }
        trail pop(this)

        if (allGood) {
            allResolved = true
        } else {
            res wholeAgain(this, "Waiting on some statements to resolve")
        }

        return Response OK

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        body replace(oldie as Statement, kiddo as Statement)
    }

    getBody: func -> List<Statement> { body }

    isResolved: func -> Bool {
        allResolved
    }

}
