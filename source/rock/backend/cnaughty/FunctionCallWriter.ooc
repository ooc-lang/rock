
import ../../middle/[FunctionDecl, FunctionCall, TypeDecl, Argument,
        Type, Expression, InterfaceDecl, VariableAccess, VariableDecl,
        ClassDecl, Dereference]
import Skeleton, FunctionDeclWriter, ModuleWriter

FunctionCallWriter: abstract class extends Skeleton {

    /** @see FunctionDeclWriter */
    write: static func ~functionCall (this: Skeleton, fCall: FunctionCall) {
        //"|| Writing function call %s (expr = %s)" format(fCall name, fCall expr ? fCall expr toString() : "(nil)") println()

        if(!fCall ref) {
            Exception new(This, "Trying to write unresolved function %s\n" format(fCall toString())) throw()
        }
        fDecl : FunctionDecl = fCall ref

        shouldCastThis := false

        // write the function name
        if(fDecl vDecl != null) {
            current app("((")
            ModuleWriter writeFuncPointer(this, fDecl getType(), "")
            current app(") ")

            if(fCall expr != null) {
                arrow := true
                // Kick all dereference exprs for the analysis.
                expr := fCall expr
                while(expr instanceOf?(Dereference)) {
                    expr = expr as Dereference expr
                }
                if(expr instanceOf?(VariableAccess)) {
                    acc := expr as VariableAccess
                    if(acc getRef() instanceOf?(VariableDecl)) {
                        vDecl := acc getRef() as VariableDecl
                        arrow = vDecl getType() getRef() instanceOf?(ClassDecl)
                    }
                }
                current app(fCall expr). app(arrow ? "->" : ".")
            }
            current app(fDecl vDecl getFullName())
            current app(".thunk)")
        } else {
            FunctionDeclWriter writeFullName(this, fDecl)
            if(fDecl isFinal) {
                if(fDecl owner instanceOf?(ClassDecl)) {
                    shouldCastThis = true
                }
            } else if(fCall getName() == "super") {
                // if super call to a non-final method, add _impl
                // and still need casting
                current app("_impl")
                shouldCastThis = true
            } else if(!fCall virtual) {
                current app("_impl")
                // and no need to cast this, it should already be of the good type
                // (esp. for interfaces, since the struct-initialization is handled by the Cast node)
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
            if(shouldCastThis || !(callType equals?(declType))) {
                // If this is a ref call, we should write down the referenced type that is passed as the callType (as determined in tinkering phase)
                current app("("). app(fDecl isThisRef ? callType : declType). app(") ")
            }

            if(fDecl isThisRef) current app("&("). app(fCall expr). app(")")
            else                current app(fCall expr)
        }

        /* Step 2 : write generic return arg, if any */
        k := 0
        for(retArg in fCall getReturnArgs()) {
            if(isFirst) {
                isFirst = false
            } else {
                current app(", ")
            }

            if(retArg) {
                if(retArg getType() isGeneric() || !fDecl getReturnArgs() get(k) getType() isGeneric()) {
                    current app(retArg)
                } else {
                    // FIXME hardcoding uint8_t is probably a bad idea. Ain't it?
                    current app("(uint8_t*) "). app(retArg)
                }
            } else {
                // ignored returnArg
                current app("NULL")
            }
            k += 1
        }
        for(i in k..fDecl getReturnArgs() getSize()) {
            if(isFirst) {
                isFirst = false
            } else {
                current app(", ")
            }
            current app("NULL")
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

            writeCast := false

            declArg : Argument = null
            if(i < fDecl args getSize())                         declArg = fDecl args get(i)
            if(declArg != null && declArg instanceOf?(VarArg)) declArg = null

            writeRefAddrOf := true
            if(declArg != null) {
                if(declArg getType() isGeneric()) {
                    current app("(uint8_t*) ")
                    if (arg instanceOf?(VariableAccess)) {
                        writeRefAddrOf = false
                    }
                } else if(arg getType() != null && declArg getType() != null && arg getType() inheritsFrom?(declArg getType())) {
                    //printf("%s inherits from %s, casting!\n", arg getType() toString(), declArg getType() toString())
                    current app("("). app(declArg getType()). app(") (")
                    writeCast = true
                }
            }

            match (writeRefAddrOf) {
                case true => arg accept(this)
                case false => visitVariableAccess(arg as VariableAccess, false)
            }
            if(writeCast) current app(')')
            i += 1
        }

        /* Step 5: write closure context, if any */
        if(fDecl vDecl != null) {
            if(isFirst) isFirst = false
            else        current app(", ")

            if(fCall expr != null) {
                arrow := true
                // Kick all dereference exprs for the analysis.
                expr := fCall expr
                while(expr instanceOf?(Dereference)) {
                    expr = expr as Dereference expr
                }
                if(expr instanceOf?(VariableAccess)) {
                    acc := expr as VariableAccess
                    if(acc getRef() instanceOf?(VariableDecl)) {
                        vDecl := acc getRef() as VariableDecl
                        arrow = vDecl getType() getRef() instanceOf?(ClassDecl)
                    }
                }
                current app(fCall expr). app(arrow ? "->" : ".")
            }
            current app(fDecl vDecl getFullName()). app(".context")
        }

        current app(')')

    }

}

