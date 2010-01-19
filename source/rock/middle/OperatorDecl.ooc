import ../frontend/Token
import FunctionDecl, Expression, Type, Visitor, Node
import tinker/[Resolver, Response, Trail]

OperatorDecl: class extends Expression {

    symbol : String
    fDecl = null : FunctionDecl

    init: func ~opDecl (=symbol, .token) {
        super(token)
    }
    
    setFunctionDecl: func (=fDecl) {
        // build fDecl name here!
        
    }
    
    accept: func (visitor: Visitor) { visitor visitFunctionDecl(fDecl) }

    getType: func -> Type { fDecl getType() }
    
    toString: func -> String {
        "operator " + symbol + (fDecl ? fDecl toString() : "")
    }
    
    isResolved: func -> Bool { false }
    
    resolve: func (trail: Trail, res: Resolver) -> Response { fDecl resolve(trail, res) }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
    isScope: func -> Bool { true }
    
}
