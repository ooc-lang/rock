import structs/[HashMap, ArrayList]
import ../frontend/[Token, SourceReader]
import Node, FunctionDecl, Visitor, Import, Include, Use

Module: class extends Node {

    fullName, simpleName : String
    
    functions := HashMap<FunctionDecl> new()
    
    includes := ArrayList<Include> new()
    imports  := ArrayList<Import> new()
    uses     := ArrayList<Use> new()

    init: func ~module (=fullName, .token) {
        super(token)
        simpleName = fullName
    }
    
    addFunction: func (f: FunctionDecl) {
        functions add(f name, f)
    }
    
    accept: func (visitor: Visitor) { visitor visitModule(this) }

}
