import ../frontend/Token
import ClassDecl, Type, FunctionDecl, TypeDecl
import structs/HashMap
import tinker/[Response, Resolver, Trail]

FunctionAlias: class {
    
    key, value: FunctionDecl
    init: func ~funcAlias(=key, =value) {}
    
    toString: func -> String { "alias %s <=> %s" format(key toString(), value toString()) }
    
}

InterfaceImpl: class extends ClassDecl {
    
    impl: ClassDecl
    aliases := HashMap<String, FunctionAlias> new()
    
    init: func ~interf(.name, interfaceType: Type, =impl, .token) {
        super(name, interfaceType, token)
        module      = impl module
        meta module = impl module
    }
    
    getAliases: func -> HashMap<String, FunctionDecl> { aliases }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if(!super(trail, res) ok()) return Responses LOOP
        
        ref := superType getRef() as TypeDecl
        if(ref == null) return Responses LOOP
        
        // done already.
        if(aliases size() == ref getMeta() getFunctions() size()) return Responses OK
        
        for(key: FunctionDecl in ref getMeta() getFunctions()) {
            hash := hashName(key)
            alias := aliases get(hash)
            if(alias == null) {
                //FIXME: smarter strategy needed here to match functions - also, check signatures
                value := impl getMeta() getFunction(key getName(), key getSuffix(), null, true)
                if(value == null) {
                    token throwError("%s must implement function %s, from interface %s\n" format(
                        impl getName(), key toString(), superType toString()))
                }
                aliases put(hash, FunctionAlias new(key, value))
            }
        }
        
        return Responses OK
        
    }
    
}
