import structs/[List, ArrayList]
import ../frontend/Token
import Expression, Visitor, Type, Node, VariableDecl, FunctionDecl, Statement
import tinker/[Trail, Resolver, Response]

CommaSequence: class extends Expression {

    body := ArrayList<Statement> new()

    init: func ~commaSeq (.token) {
        super(token)
    }

    clone: func -> This {
        copy := new(token)
        body each(|e| copy body add(e clone()))
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitCommaSequence(this)
    }

    getType: func -> Type { body empty?() ? null : body last() as Expression getType() }

    toString: func -> String {
        return "(comma expr)"
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)
        for (statement in body) {
            response := statement resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)

        return Responses OK

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        body replace(oldie as Statement, kiddo as Statement)
    }

    getBody: func -> List<Statement> { body }

}
