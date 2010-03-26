import ../../middle/[FunctionDecl, FunctionCall, TypeDecl, Argument, Type, Expression, InterfaceDecl]
import Skeleton, FunctionDeclWriter

FunctionCallWriter: abstract class extends Skeleton {
    
    /** @see FunctionDeclWriter */
    write: static func ~functionCall (this: This, fCall: FunctionCall) {
        //"|| Writing function call %s (expr = %s)" format(fCall name, fCall expr ? fCall expr toString() : "(nil)") println()

        if(!fCall ref) {
            Exception new(This, "Trying to write unresolved function %s\n" format(fCall toString())) throw()
        }
        fDecl : FunctionDecl = fCall ref
        
        // write the function name
        if(fDecl vDecl != null) {
            if(fCall expr != null) {
                current app(fCall expr). app("->")
            }
            current app(fCall getName())
        } else {
            FunctionDeclWriter writeFullName(this, fDecl)
            if(!fDecl isFinal && fCall getName() == "super") {
                current app("_impl")
            }
        }
        
        current app('(')
        isFirst := true
        
        /* Step 1: write this, if any
         * for example, call to member function pointers (fDecl vDecl != null) don't need a this */
        if(!fDecl isStatic() && fCall isMember() && fDecl vDecl == null) {
            isFirst = false
            callType := fCall expr getType()
            declType := fDecl owner getInstanceType()
            
            // TODO maybe check there's some kind of inheritance/compatibility here?
            // or in the tinker phase?
            if(!(callType equals(declType))) {
                current app("("). app(declType). app(") ")
            }
        
            if(fDecl isThisRef) current app("&("). app(fCall expr). app(")")
            else                current app(fCall expr) 
        }
    
        /* Step 2 : write generic return arg, if any */
        if(fDecl getReturnType() isGeneric()) {
            if(isFirst) {
                isFirst = false
            } else {
                current app(", ")
            }
            
            retArg := fCall getReturnArg()
            if(retArg) {
                if(retArg getType() isGeneric()) {
                    current app(retArg)
                } else {
                    // FIXME hardcoding uint8_t is probably a bad idea. Ain't it?
                    current app("(uint8_t*) "). app(retArg)
                }
            } else {
                current app("NULL")
            }
        }
    
        /* Step 3 : write generic type args */
        i := 0
        for(typeArg in fCall typeArgs) {
            ghost := false
            for(arg in fDecl args) {
                if(arg getName() == fDecl typeArgs get(i) getName()) {
                    ghost = true
                    break
                }
            }
            
            if(!ghost) {
                if(isFirst) isFirst = false
                else        current app(", ")
                // FIXME: it's really ugly to hardcode class
                // it should be resolved once and for all in Resolver and used from there.
                current app("(lang_types__Class*)"). app(typeArg)
            }
            
            i += 1
        }
        
        /* Step 4 : write real args */
        i = 0
        for(arg: Expression in fCall args) {
            if(isFirst) {
                isFirst = false
            } else {
                current app(", ")
            }
            
            declArg : Argument = null
            if(i < fDecl args size())                         declArg = fDecl args get(i)
            if(declArg != null && declArg instanceOf(VarArg)) declArg = null
            
            if(declArg != null) {
                if(declArg getType() isGeneric()) {
                    current app("(uint8_t*) ")
                } else if(arg getType() != null && declArg getType() != null && arg getType() inheritsFrom(declArg getType())) {
                    //printf("%s inherits from %s, casting!\n", arg getType() toString(), declArg getType() toString())
                    current app("("). app(declArg getType()). app(")")
                }
            }
            
            arg accept(this)
            i += 1
        }
        current app(')')
        
        /* Step 4 : write exception handling arguments */
        // TODO
    }
    
}

