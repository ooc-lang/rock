import structs/[List, ArrayList, HashMap]
import ../../middle/[Cast, InterfaceDecl, TypeDecl, Type]
import Skeleton

CastWriter: abstract class extends Skeleton {

    write: static func ~cast (this: Skeleton, cast: Cast) {

        if(cast inner getType() isGeneric() && cast inner getType() pointerLevel() == 0) {

            current app("(* ("). app(cast type). app("*)"). app(cast inner). app(')')

        } else if(cast getType() getRef() instanceOf?(InterfaceDecl)) {

            iDecl := cast getType() getRef() as InterfaceDecl

            implementor := getImplementor(cast inner getType() getRef() as TypeDecl, iDecl getType())
            if(implementor == null) {
                Exception new(This, "Couldn't find implementor for %s in %s\n" format(iDecl toString(), cast inner getType() getRef() toString())) throw()
            }

            current app("(struct _"). app(iDecl getFatType() getInstanceType()). app(") {").
                app(".impl = "). app(implementor underName()). app("__impl__"). app(iDecl getName()). app("_class(), .obj = (lang_types__Object*) ").
                app(cast inner). app('}')

        } else {

            current app("(("). app(cast type). app(") ("). app(cast inner). app("))")

        }

    }

    getImplementor: static func (typeDecl: TypeDecl, haystack: Type) -> TypeDecl {

        //printf("Searching for implementor of %s in %s\n", haystack toString(), typeDecl toString())
        for(impl in typeDecl getInterfaceDecls()) {
            //printf("%s vs %s\n", impl getSuperRef() getType() toString(), haystack toString())
            if(impl getSuperRef() getType() equals?(haystack)) {
                //printf("Found %s\n", impl toString())
                return typeDecl
            }
        }

        if(typeDecl getSuperRef() != null && !typeDecl getSuperRef() isClassClass()) {
            result := getImplementor(typeDecl getSuperRef(), haystack)
            if(result != null) return result
        }

        return null

    }

}

