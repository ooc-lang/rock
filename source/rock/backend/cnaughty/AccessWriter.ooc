
import rock/middle/[VariableDecl, Expression, ClassDecl, CoverDecl, Type, BaseType]
import rock/middle/tinker/[Errors]
import rock/frontend/[Token]

import Skeleton

AccessWriter: abstract class extends Skeleton {

    writeVariableDeclAccess: static func (this: Skeleton, vDecl: VariableDecl, isMember: Bool,
        expr: Expression, token: Token, writeReferenceAddrOf: Bool) {

        if(isMember && !(vDecl isExtern() && vDecl isStatic())) {
            casted := false

            // Cover types don't need to be cast before accessing their members (in fact, it is harmful, see issue #949)
            // Effectively, for the owner of the decl not to be of the same type as the expr, we must have cover hierarchy, which is expressed
            // through typedefs.
            coverType? := vDecl owner instanceOf?(CoverDecl)

            if(!coverType? && vDecl owner != expr getType() getRef()) {
                casted = true
                current app("(("). app(vDecl owner getInstanceType()) .app(')')
            }

            current app(expr)

            if(casted) current app(")")

            refLevel := 0


            if(expr getType() getRef() instanceOf?(ClassDecl)) {
                refLevel += 1
            }

            current app(match (refLevel) {
                case 0 => "."
                case 1 => "->"
                case   =>
                    message := "This is too much reference %d! Can't write it." format(refLevel)
                    params errorHandler onError(InternalError new(token, message))
                    ""
            })
        }

        paren := false
        if(vDecl getType() instanceOf?(ReferenceType)) {
            if (writeReferenceAddrOf) {
                current app("(*")
                paren = true
            }
        }

        if(vDecl isExternWithName()) {
            current app(vDecl getExternName())
        } else {
            current app(vDecl getFullName())
        }

        if(paren) current app(')')
    }

}

