import ../frontend/Token
import ControlStatement, Expression, Visitor, VariableDecl, Node,
       VariableAccess, VariableDecl

Foreach: class extends ControlStatement {
    
    variable: Expression
    collection: Expression

    init: func ~_while (=variable, =collection, .token) {
        "New foreach!" println()
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
    
    resolveAccess: func (access: VariableAccess) {
        
        println("Looking for " + access toString() + " in " + toString() + " and variable is a " + variable class name)
        if(variable instanceOf(VariableDecl)) {
            vDecl := variable as VariableDecl
            println("Got vDecl " + vDecl toString())
            if(vDecl name == access name) {
                access suggest(vDecl)
            }
        }
        
    }
    
}
