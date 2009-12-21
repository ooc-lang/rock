import ../middle/[FunctionDecl, FunctionCall, TypeDecl, Argument, Type, Expression]
import Skeleton, FunctionDeclWriter

FunctionCallWriter: abstract class extends Skeleton {
    
    /** @see FunctionDeclWriter */
    write: static func ~functionCall (this: This, fCall: FunctionCall) {
        //"|| Writing function call %s (expr = %s)" format(fCall name, fCall expr ? fCall expr toString() : "(nil)") println()

        if(!fCall ref) {
            Exception new(This, "Trying to write unresolved function %s\n" format(fCall toString())) throw()
        }
        fDecl : FunctionDecl = fCall ref
        
        FunctionDeclWriter writeFullName(this, fCall ref)
        current app('(')
        isFirst := true
        
        /* Step 1: write this, if any */
        if(fCall expr) {
            isFirst = false
            current app(fCall expr) 
        }
    
        /* Step 2 : write generic type args */
        for(typeArg in fCall typeArgs) {
            if(isFirst) {
                isFirst = false
            } else {
                current app(", ")
            }
            current app(typeArg)
        }
        
        /* Step 3 : write real args */
        i := 0
        for(arg: Expression in fCall args) {
            if(isFirst) {
                isFirst = false
            } else {
                current app(", ")
            }
            isGeneric := i < fDecl args size()
            if(isGeneric) isGeneric = fDecl args get(i) getType() isGeneric()
            if(isGeneric) {
                current app("(uint8_t*) (&")
            }
            arg accept(this)
            if(isGeneric) {
                current app(")")
            }
            i += 1
        }
        current app(')')
        
        /* Step 4 : write exception handling arguments */
        // TODO
    }
    
}

