import structs/HashMap
import ../frontend/Token
import Expression, Line, Type, Visitor, Declaration, VariableDecl, FunctionDecl

TypeDecl: abstract class extends Declaration {

    name: String

    variables := HashMap<VariableDecl> new()
    functions := HashMap<FunctionDecl> new()

    type: Type
    superType: Type
    
    init: func ~typeDecl (=name, =superType, .token) {
        super(token)
        type = Type new(name)
    }
    
    getFunction: func (fName, fSuffix: String) -> FunctionDecl {
        // TODO add suffix handling
        functions get(fName)
    }
    
    getVariable: func (vName: String) -> VariableDecl {
        variables get(vName)
    }
    
    underName: func -> String {
        // TODO underize it.
        name
    }
    
    superRef: func -> TypeDecl {
        superType ? superType ref : null
    }

}
