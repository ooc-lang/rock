import structs/[ArrayList, List]
import ../frontend/Token
import ControlStatement, Statement, Expression, Visitor, VariableDecl,
       Node, VariableAccess, Scope, BoolLiteral, Comparison
import tinker/[Trail, Resolver, Response]

Match: class extends Statement {
    
    expr: Expression = null
    cases := ArrayList<Case> new()

    init: func ~match_ (.token) {
        super(token)
    }
    
    getExpr: func -> Expression { expr }
    setExpr: func (=expr) {}
    
    getCases: func -> List<Case> { cases }
    
    addCase: func (caze: Case) {
        cases add(caze)
        
        if(expr && caze getExpr()) {
            // hideous, but obvious
            if(!(expr instanceOf(BoolLiteral) && expr as BoolLiteral getValue() == true)) {
                caze setExpr(Comparison new(expr, caze getExpr(), CompTypes equal, caze getExpr() token))
            }
        }
    }
    
    accept: func (visitor: Visitor) {
        visitor visitMatch(this)
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo; true
            case      => false
        }
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if (expr != null) {
            response := expr resolve(trail, res)
            if(!response ok()) return response
        }
        
        trail push(this)
        for (c in cases) {
            response := c resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        trail pop(this)
        
        return Responses OK
        
    }
    
}

Case: class extends ControlStatement {

    expr: Expression

    init: func ~_case (.token) {
        super(token)
    }

    accept: func (visitor: Visitor) {}
    
    getExpr: func -> Expression { expr }
    setExpr: func (=expr) {}
    
    resolveAccess: func (access: VariableAccess) {
        body resolveAccess(access)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if (expr != null) {
            response := expr resolve(trail, res)
            if(!response ok()) return response
        }
        
        return body resolve(trail, res)
        
    }
    
}

