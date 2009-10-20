import structs/[HashMap, ArrayList]
import ../frontend/[Token, SourceReader]
import Node, FunctionDecl, Visitor, Import, Include, Use, TypeDecl

Module: class extends Node {

    fullName, simpleName : String
    
    types     := HashMap<TypeDecl> new()
    functions := HashMap<FunctionDecl> new()
    
    includes := ArrayList<Include> new()
    imports  := ArrayList<Import> new()
    uses     := ArrayList<Use> new()

    init: func ~module (=fullName, .token) {
        super(token)
        simpleName = fullName
    }
    
    addFunction: func (fDecl: FunctionDecl) {
        functions add(fDecl name, fDecl)
    }
    
    addType: func (t: TypeDecl) {
        
    }
    
    accept: func (visitor: Visitor) { visitor visitModule(this) }

}
