import ../../middle/[FunctionDecl, TypeDecl, ClassDecl, Argument, Type, InterfaceDecl]
import Skeleton, CGenerator, ClassDeclWriter, VersionWriter
import ../../frontend/BuildParams
include stdint

ArgsWriteMode: cover from Int32

ArgsWriteModes: class {
    FULL = 1,
    NAMES_ONLY = 2,
    TYPES_ONLY = 3 : static const Int32
}

FunctionDeclWriter: abstract class extends Skeleton {

    write: static func ~function (this: Skeleton, fDecl: FunctionDecl) {
        //"|| Writing function %s" format(fDecl name) println()

        if(!fDecl isExtern() || fDecl isProto()) {

            // header
            current = fw
            if(fDecl getVersion()) VersionWriter writeStart(this, fDecl getVersion())
            current nl()
            if(fDecl isProto()) current app("extern ")
            writeFuncPrototype(this, fDecl)
            current app(';')
            if(fDecl getVersion()) VersionWriter writeEnd(this)

        }

        if(fDecl isExtern()) {
            // write a #define for extern functions.
            current = fw
            if(fDecl getVersion()) VersionWriter writeStart(this, fDecl getVersion())
            current nl()

            externName := fDecl getExternName()
            if(externName empty?())
                externName = fDecl getName()

            current app("#define ") .app(fDecl getFullName()) \
                   .app(' ') .app(externName) .nl()

            if(fDecl getVersion()) VersionWriter writeEnd(this)

            // don't write to source.
            return
        }

        // source
        current = cw
        if(fDecl getVersion()) VersionWriter writeStart(this, fDecl getVersion())
        current nl(). nl()
        writeFuncPrototype(this, fDecl)
        current app(" {"). tab()

        if(params enableGC && fDecl isEntryPoint()) current nl(). app("GC_INIT();")
        if(fDecl isEntryPoint()) current nl(). app(module getLoadFuncName()). app("();")

        for(stat in fDecl body) {
            writeLine(stat)
        }
        current untab(). nl(). app("}")
        if(fDecl getVersion()) VersionWriter writeEnd(this)
    }

    /** Write the name of a function, with its suffix, and prefixed by its owner if any */
    writeFullName: static func (this: Skeleton, fDecl: FunctionDecl) {
        //printf("Writing full name of %s, owner = %s\n", fDecl name, fDecl owner ? fDecl owner toString() : "(nil)")
        current app(fDecl getFullName())
    }

    /** Write the name of a function, with its suffix and without any module prefixes */
    writeSuffixedName: static func (this: Skeleton, fDecl: FunctionDecl) {
        current app(fDecl name)
        if(fDecl suffix) {
            current app("_"). app(fDecl suffix)
        }
    }

    /** Write the arguments of a function (default params) */
    writeFuncArgs: static func ~defaults (this: Skeleton, fDecl: FunctionDecl) {
        writeFuncArgs(this, fDecl, ArgsWriteModes FULL, null)
    }

    /**
     * Write the arguments of a function
     *
     * @param baseType For covers, the 'this' must be casted otherwise
     * the C compiler complains about incompatible pointer types. Or at
     * least that's my guess as to its utility =)
     *
     * @see FunctionCallWriter
     */
    writeFuncArgs: static func (this: Skeleton, fDecl: FunctionDecl, mode: ArgsWriteMode, baseType: TypeDecl) {

        current app('(')
        isFirst := true

        isInterface := false
        owner := fDecl getOwner()
        if(owner != null) {
            match(owner isMeta ? owner getNonMeta() : owner) {
                case iDecl: InterfaceDecl =>
                    isInterface = true
            }
        }

        /* Step 1 : write this, if any */
        iter := fDecl args iterator() as Iterator<Argument>
        if(fDecl isMember() && !fDecl isStatic()) {
            isFirst = false

            type := (fDecl isThisRef ? fDecl owner thisRefDecl : fDecl owner thisDecl) getType()

            match mode {
                case ArgsWriteModes NAMES_ONLY =>
                    if(baseType != null && !isInterface) {
                        current app("("). app(baseType getNonMeta() getInstanceType()). app(")")
                    }
                    current app("this")
                    if(isInterface) current app(".obj")
                case ArgsWriteModes TYPES_ONLY =>
                    if(isInterface) {
                        current app("void*")
                    } else {
                        current app(type)
                    }
                case =>
                    type write(current, "this")
            }
        }

        /* Step 2: write the return arguments, if any */
        for(retArg in fDecl getReturnArgs()) {
            if(!isFirst) current app(", ")
            else isFirst = false

            match mode {
                case ArgsWriteModes NAMES_ONLY =>
                    current app(retArg getName())
                case ArgsWriteModes TYPES_ONLY =>
                    current app(retArg getType())
                case =>
                    current app(retArg)
            }
        }

        /* Step 3 : write generic type args */
        for(typeArg in fDecl typeArgs) {
            ghost := false
            for(arg in fDecl args) {
                if(arg getName() == typeArg getName()) {
                    ghost = true
                    break
                }
            }

            if(!ghost) {
                if(!isFirst) current app(", ")
                else isFirst = false

                match mode {
                    case ArgsWriteModes NAMES_ONLY =>
                        current app(typeArg getName())
                    case ArgsWriteModes TYPES_ONLY =>
                        current app(typeArg getType())
                    case =>
                        current app(typeArg)
                }
            }
        }

        /* Step 4 : write real args */
        while(iter hasNext?()) {
            arg := iter next()
            if(!isFirst) current app(", ")
            else isFirst = false

            match mode {
                case ArgsWriteModes NAMES_ONLY =>
                    current app(arg name)
                case ArgsWriteModes TYPES_ONLY =>
                    {
                        if(arg instanceOf?(VarArg)) {
                            current app("...")
                        } else {
                            current app(arg type)
                        }
                    }
                case =>
                    current app(arg)
            }
        }

        current app(')')

    }

    writeFuncPrototype: static func ~defaults (this: Skeleton, fDecl: FunctionDecl) {
        writeFuncPrototype(this, fDecl, null)
    }


    writeFuncPrototype: static func (this: Skeleton, fDecl: FunctionDecl, additionalSuffix: String) {
        // functions that return a generic value are actually void
        // the return takes place with a memcpy/assignment to the returnArg
        if(fDecl getReturnType() isGeneric()) {
            current app("void ")
        } else {
            current app(fDecl returnType). app(' ')
        }

        if(fDecl isProto()) {
            current app(fDecl isExternWithName() ? fDecl getExternName() : fDecl getName())
        } else {
            writeFullName(this, fDecl)
        }

        if(additionalSuffix) current app(additionalSuffix)

        writeFuncArgs(this, fDecl)
    }

}
