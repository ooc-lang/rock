import structs/[ArrayList, List]
import text/Buffer

import ../frontend/Token

import tinker/[Resolver, Trail]
import Declaration, Import, Type, Visitor, Node, VariableAccess,
       FunctionCall, BaseType

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
        sb := Buffer new()
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
    
    resolveType: func (type: BaseType) {
        
        for(imp in imports) {
            imp getModule() resolveType(type)
        }
        
    }
    
    resolveCall: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        
        for(imp in imports) {
            imp getModule() resolveCall(call, res, trail)
        }
        
        0
        
    }
    
    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        
        for(imp in imports) {
            imp getModule() resolveAccess(access, res, trail)
        }
        
        0
        
    }
    
}
