import ../frontend/Token
import ControlStatement, Expression, Visitor, VariableDecl, Node,
       VariableAccess, VariableDecl, IntLiteral, Type, RangeLiteral
import tinker/[Trail, Resolver, Response]

Foreach: class extends ControlStatement {
    
    variable: Expression
    collection: Expression

    init: func ~_foreach (=variable, =collection, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitForeach(this)
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case variable   => variable   = kiddo; return true
            case collection => collection = kiddo; return true
        }
        return super replace(oldie, kiddo)
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if(variable instanceOf(VariableAccess)) {
            varType : Type = null
            if(collection instanceOf(RangeLiteral)) {
                varType = IntLiteral type
            }
            variable = VariableDecl new(varType, variable as VariableAccess getName(), variable token)
        }
        
        {
            response := variable resolve(trail, res)
            if(!response ok()) return response
        }
        
        {
            response := collection resolve(trail, res)
            if(!response ok()) return response
        }
        
        return super resolve(trail, res)
        
    }
    
    resolveAccess: func (access: VariableAccess) {
        
        if(variable instanceOf(VariableDecl)) {
            vDecl := variable as VariableDecl
            if(vDecl name == access name) {
                access suggest(vDecl)
            }
        }
        
    }
    
}
