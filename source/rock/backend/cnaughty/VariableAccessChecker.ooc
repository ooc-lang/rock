
import rock/frontend/[BuildParams, Token]
import rock/middle/[VariableAccess, VariableDecl, ClassDecl, Module]
import rock/middle/tinker/[Errors]

VariableAccessChecker: class {

    /**
     * Check if additional imports are needed to make the C code work.
     * This happens in the following case: module a accesses a variable
     * on an instance of class C, which it got through module b.
     * Module b references c directly, so it must have imported it,
     * but module a never references c directly, only b, so it might have
     * passed through the middle-end without throwing an error.
     *
     * The C compiler however will see that as accessing a member of
     * an incomplete type. We could go ahead and add an import ourselves here,
     * but it might completely change the result of the compilation and
     * we don't want that to happen - instead we leave it to the users to
     * do that.
     */
    check: static func (params: BuildParams, vAcc: VariableAccess) {
        ref := vAcc ref

        // we only care about access to real variables, not properties
        if (!ref instanceOf?(VariableDecl)) return

        vDecl := ref as VariableDecl
        owner := vDecl getOwner()

        // we only care about owned variables
        if (!vAcc expr || !owner) return

        typeRef := vAcc expr getType() getRef()

        // we only care if we know the modules
        if (!vAcc token module) return
        if (!owner token module) return
        if (!typeRef token module) return

        // check if we need to import anything
        valid := vAcc token module hasLink?(owner token module)
        if (!valid) {
            message := "Module `%s` must be imported to access the variable `%s` from %s" format(
                typeRef token module fullName, vAcc prettyName, typeRef toString())
            params errorHandler onError(ImportRequired new(vAcc token, message))
        }
    }

}

ImportRequired: class extends Error {
    init: super func ~tokenMessage
}

