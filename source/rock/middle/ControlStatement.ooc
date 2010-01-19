import structs/ArrayList
import ../frontend/Token
import Statement, Scope, VariableAccess, Node
import tinker/[Trail, Resolver, Response]

ControlStatement: abstract class extends Statement {

    body := Scope new()
    
    init: func (.token) { super(token) }
    
    resolveAccess: func (access: VariableAccess) {
        body resolveAccess(access)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        //printf("Resolving an %s\n", class name)
        trail push(this)
        response := body resolve(trail, res)
        trail pop(this)
        return response
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        return body replace(oldie, kiddo)
    }
    
    addBefore: func (mark, newcomer: Node) -> Bool {
        body addBefore(mark, newcomer)
    }
    
    addAfter: func (mark, newcomer: Node) -> Bool {
        body addAfter(mark, newcomer)
    }
    
    isScope: func -> Bool { true }
    
    getBody: func -> Scope { body }
    
}
