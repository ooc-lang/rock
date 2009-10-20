import structs/HashMap
import ../frontend/Token
import Expression, Line, Type, Visitor, Declaration, VariableDecl, FunctionDecl

TypeDecl: abstract class extends Declaration {

    name: String

    variables := HashMap<VariableDecl> new()
    functions := HashMap<FunctionDecl> new()
    
    superType: Type
    
    init: func ~typeDecl (=name, =superType, .token) { super(token) }
    
    getFunction: func (fName, fSuffix: String) -> FunctionDecl {
        // TODO add suffix handling
        functions get(fName)
    }
    
    getVariable: func (vName: String) -> VariableDecl {
        variables get(vName)
    }

}
