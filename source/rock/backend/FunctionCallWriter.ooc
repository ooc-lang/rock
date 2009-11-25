import ../middle/[FunctionDecl, FunctionCall, TypeDecl, Argument, Line, Type, Expression]
import Skeleton, FunctionDeclWriter

FunctionCallWriter: abstract class extends Skeleton {
    
    write: static func ~functionCall (this: This, fCall: FunctionCall) {
        //"|| Writing function call %s" format(fCall name) println()

        if(!fCall ref) {
            Exception new(This, "Trying to write unresolved function %s\n" format(fCall toString())) throw()
        }
        
        FunctionDeclWriter writeFullName(this, fCall ref)
        current app('(')
        isFirst := true
        
        if(fCall expr) {
            isFirst = false
            current app(fCall expr)
        }
        
        for(arg: Expression in fCall args) {
            if(isFirst) {
                isFirst = false
            } else {
                current app(", ")
            }
            arg accept(this)
        }
        current app(')')
    }
    
}

