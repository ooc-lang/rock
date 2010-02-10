import structs/[ArrayList, List]
import text/StringBuffer

import ../frontend/Token
import Declaration, Import, Type, Visitor, Node, VariableAccess

NamespaceDecl: class extends Declaration {
    
    name: String
    imports := ArrayList<Import> new()
    
    init: func~namespace(=name) {
        super(nullToken)
    }
    
    accept: func (v: Visitor) {}
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
    addImport: func (imp: Import) { imports add(imp) }
    getImports: func -> List<Import> { imports }
    
    getName: func -> String { name }
    
    getType: func -> Type { null }
    
    toString: func -> String {
        sb := StringBuffer new()
        sb append("[")
        isFirst := true
        for(imp in imports) {
            if(isFirst) isFirst = false
            else        sb append(", ")
            sb append(imp path)
        }
        sb append("] into "). append(name)
        sb toString()
    }
    
    resolveType: func (type: Type) {
        
        printf("[Namespace] Looking for type %s in %s\n", type toString(), toString())
        
    }
    
    resolveAccess: func (access: VariableAccess) {
        
        printf("[Namespace] Looking for %s in %s\n", access toString(), toString())
        for(imp in imports) {
            imp getModule() resolveAccess(access)
        }
        
    }
    
}
