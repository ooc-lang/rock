import structs/[ArrayList]
import Line, VariableAccess, VariableDecl

Scope: class extends ArrayList<Line> {
    
    init: func ~scope {
        T = Line
        super()
    }
    
    resolveAccess: func (access: VariableAccess) {
        for(line in this) {
            line inner resolveAccess(access)
        }
    }
    
}

