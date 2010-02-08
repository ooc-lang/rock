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
    aliases := HashMap<FunctionAlias> new()
    
    init: func ~interf(.name, interfaceType: Type, =impl, .token) {
        super(name, interfaceType, token)
        module      = impl module
        meta module = impl module
    }
    
    getAliases: func -> HashMap<FunctionDecl> { aliases }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        if(!super resolve(trail, res) ok()) return Responses LOOP
        
        ref := superType getRef() as TypeDecl
        if(ref == null) return Responses LOOP
        
        // done already.
        if(aliases size() == ref getMeta() getFunctions() size()) return Responses OK
        
        printf("[KALAMAZOO] reviewing functions in %s. getMeta() = %s\n", ref toString(), ref getMeta() ? ref getMeta() toString() : "(nil)")
        for(key: FunctionDecl in ref getMeta() getFunctions()) {
            hash := hashName(key)
            alias := aliases get(hash)
            if(alias == null) {
                printf("[KALAMAZOO] Yet has to resolve %s for %s to implement %s\n", key toString(), impl toString(), superType toString())
                //FIXME: smarter strategy needed here to match functions - also, check signatures
                value := impl getMeta() getFunction(key getName(), key getSuffix(), null, true)
                if(value == null) {
                    token throwError("Couldn't find function %s in class %s, neeeded to implement interface %s\n" format(
                        key toString(), impl toString(), superType toString()))
                }
                aliases put(hash, FunctionAlias new(key, value))
            }
        }
        
    }
    
}
