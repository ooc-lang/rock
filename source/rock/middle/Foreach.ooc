import ../frontend/Token
import ControlStatement, Expression, Visitor, VariableDecl, Node,
       VariableAccess, VariableDecl
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
            case variable   => variable   = kiddo; true
            case collection => collection = kiddo; true
            case => false
        }
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
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
        
        println("Looking for " + access toString() + " in " + toString() + " and variable is a " + variable toString())
        if(variable instanceOf(VariableDecl)) {
            vDecl := variable as VariableDecl
            println("Got vDecl " + vDecl toString())
            if(vDecl name == access name) {
                access suggest(vDecl)
            }
        }
        
    }
    
}
