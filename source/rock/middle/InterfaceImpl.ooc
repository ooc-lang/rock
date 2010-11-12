import ../frontend/Token
import ClassDecl, Type, FunctionDecl, TypeDecl, FunctionCall,
       VariableAccess, Cast
import structs/HashMap
import tinker/[Response, Resolver, Trail, Errors]

FunctionAlias: class {

    key, value: FunctionDecl
    init: func ~funcAlias(=key, =value) {}

    toString: func -> String { "alias %s <=> %s" format(key toString(), value toString()) }

}

InterfaceImpl: class extends ClassDecl {

    impl: TypeDecl
    aliases := HashMap<String, FunctionAlias> new()

    init: func ~interf(.name, interfaceType: Type, =impl, .token) {
        super(name, interfaceType, token)
        module      = impl module
        meta module = impl module
    }

    getAliases: func -> HashMap<String, FunctionDecl> { aliases }

    isAbstract: func -> Bool { true }

    /** Trick to get TypeDecl checkAbstractFuncs() out of the way. We check it already */
    checkAbstractFuncs: func (res: Resolver) -> Bool { true }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(!super(trail, res) ok()) return Response LOOP

        ref := superType getRef() as TypeDecl
        if(ref == null) return Response LOOP

        // done already.
        if(aliases getSize() == ref getMeta() getFunctions() getSize()) return Response OK

        for(key: FunctionDecl in ref getMeta() getFunctions()) {
            hash := hashName(key)
            alias := aliases get(hash)
            if(alias == null) {
                //FIXME: smarter strategy needed here to match functions - also, check signatures
                finalScore : Int
                value := impl getMeta() getFunction(key getName(), key getSuffix(), null, true, finalScore&)
                if(finalScore == -1) {
                    res wholeAgain(this, "Not finished checking every function is implemented")
                    return Response OK
                }
                if(value == null) {
                    if(impl instanceOf?(ClassDecl) && impl as ClassDecl isAbstract) {
                        // relay unimplemented interface methods into an abstract class...
                        value = FunctionDecl new(key getName(), key token)
                        value suffix = key suffix
                        value args = key args clone()
                        value returnType = key returnType
                        value setAbstract(true)
                        impl addFunction(value)
                    } else {
                        // ...but err on concrete class, cause they should implement everything
                        // except if the function's already implemented in the interfaces (aka traits/mixins)
                        if(key hasBody) {
                            // already implemented in the interface - alright
                            value = FunctionDecl new(key getName(), key token)
                            value suffix = key suffix
                            value args = key args clone()
                            value returnType = key returnType
                            impl addFunction(value)

                            call := FunctionCall new(key getName(), key token)
                            call virtual = false
                            call expr = Cast new(VariableAccess new("this", value token), superType, value token)
                            value args each(|declArg|
                                call args add(VariableAccess new(value getName(), value token))
                            )
                            // hey that's barbaric.
                            call ref = key
                            call refScore = 1024
                            value getBody() add(call)
                        } else {
                            res throwError(InterfaceContractNotSatisfied new(token,
                                "%s must implement function %s, from interface %s\n" format(
                                impl getName(), key toString(), superType toString())))
                        }
                    }
                }
                aliases put(hash, FunctionAlias new(key, value))
            }
        }

        return Response OK

    }

}

InterfaceContractNotSatisfied: class extends Error {
    init: super func ~tokenMessage
}


