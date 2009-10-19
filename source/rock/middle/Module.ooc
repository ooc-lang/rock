import structs/HashMap
import ../frontend/[Token, SourceReader]
import Node, FunctionDecl, Visitor

Module: class extends Node {

    fullName, simpleName : String
    
    functions := HashMap<FunctionDecl> new()

    init: func ~module (=fullName, .token) {
        super(token)
        simpleName = fullName
    }
    
    addFunction: func (f: FunctionDecl) {
        functions add(f name, f)
    }
    
    accept: func (visitor: Visitor) { visitor visitModule(this) }

}
