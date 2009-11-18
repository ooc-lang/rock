import ../middle/[FunctionDecl, TypeDecl, Argument, Line, Type]
import Skeleton
include stdint

ArgsWriteMode: cover from Int32 {}

ArgsWriteModes: class {
    FULL = 1,
    NAMES_ONLY = 2,
    TYPES_ONLY = 3 : static const Int32
}

FunctionDeclWriter: abstract class extends Skeleton {
    
    /** Write a function prototype */
    writePrototype: static func (this: This, fDecl: FunctionDecl) {
        current app(fDecl returnType). app(' '). app(fDecl name). app('(')
        // TODO write args =D
        current app(')')
    }
    
    write: static func ~function (this: This, fDecl: FunctionDecl) {
        // header
        current = hw
        current nl()
        writePrototype(this, fDecl)
        current app(';')
        
        // source
        current = cw
        current nl()
        writePrototype(this, fDecl)
        current app(" {"). tab()
        for(line in fDecl body) {
            current app(line)
        }
        current untab(). nl(). app("}")
    }
    
    /** Write the name of a function, with its suffix, and prefixed by its owner if any */
    writeFullName: static func (this: This, fDecl: FunctionDecl) {
        
        if(fDecl isExtern() && !fDecl externName isEmpty()) {
            current app(fDecl externName)
        } else {
            if(fDecl isMember()) {
                current app(fDecl owner getExternName()). app('_')
            }
            writeSuffixedName(this, fDecl)
        }
    }
    
    /** Write the name of a function, with its suffix */
    writeSuffixedName: static func (this: This, fDecl: FunctionDecl) {
        current app(fDecl name)
        if(fDecl suffix) {
            current app("_"). app(fDecl suffix)
        }
    }
    
    /** Write the arguments of a function (default params) */
    writeFuncArgs: static func ~defaults (this: This, fDecl: FunctionDecl) {
        writeFuncArgs(this, fDecl, ArgsWriteModes FULL, null)
    }
    
    /** Write the arguments of a function */
    writeFuncArgs: static func (this: This, fDecl: FunctionDecl, mode: ArgsWriteMode, baseType: TypeDecl) {
        
        current app('(')
        isFirst := true

        iter := fDecl args iterator() as Iterator<Argument>
        if(fDecl hasThis() && iter hasNext()) {
            if(!isFirst) current app(", ")
            isFirst = false
            arg := iter next()
            
            match mode {
                case ArgsWriteModes NAMES_ONLY =>
                    if(baseType) {
                        current app("("). app(baseType type)
                    }
                    current app(arg name)
                case ArgsWriteModes TYPES_ONLY =>
                    current app(arg type)
                case =>
                    current app(arg)
            }
        }
        
        returnType := fDecl returnType
        // TODO add generics support
        /*
        if(returnType class instanceof(TypeParam)) {
            if(!isFirst) current.app(", ");
            isFirst = false;
            if(mode == ArgsWriteMode.NAMES_ONLY) {
                current.app(functionDecl.getReturnArg().getName());
            } else if(mode == ArgsWriteMode.TYPES_ONLY) {
                functionDecl.getReturnArg().getType().accept(cgen);
            } else {
                functionDecl.getReturnArg().accept(cgen);
            }
        }
        */
        /*
        for(TypeParam param: functionDecl.getTypeParams().values()) {
            if(param.isGhost()) continue;
            if(!isFirst) current.app(", ");
            isFirst = false;
            if(mode == ArgsWriteMode.NAMES_ONLY) {
                current.app(param.getArgument().getName());
            } else if(mode == ArgsWriteMode.TYPES_ONLY) {
                param.getArgument().getType().accept(cgen);
            } else {
                param.getArgument().accept(cgen);
            }
        }
        */
        
        while(iter hasNext()) {
            arg := iter next()
            if(!isFirst) current app(", ")
            isFirst = false
            
            match mode {
                case ArgsWriteModes NAMES_ONLY =>
                    current app(arg name)
                case ArgsWriteModes TYPES_ONLY =>
                    {
                        if(arg class instanceof(VarArg)) {
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
    
    writeFuncPrototype: static func ~defaults (this: This, fDecl: FunctionDecl) {
        writeFuncPrototype(this, fDecl, null)
    }
    
    
    writeFuncPrototype: static func (this: This, fDecl: FunctionDecl, additionalSuffix: String) {
        
        // TODO inline member functions don't work yet anyway.
        //if(functionDecl isInline()) cgen.current.append("inline ")
            
        returnType := fDecl returnType
        // TODO add function pointers and generics
        /*if (returnType ref class instanceof(TypeParam)) {
            current app("void ")
        } else if(returnType instanceof FuncType) {
            TypeWriter writeFuncPointerStart(this, returnType ref as FunctionDecl)
        } else */ {
            returnType write(current)
        }
        current app(' ')
        writeFullName(this, fDecl)
        if(additionalSuffix) current app(additionalSuffix)
        
        writeFuncArgs(this, fDecl)
        
        // TODO add function pointers
        /*if(returnType instanceof FuncType) {
            TypeWriter writeFuncPointerEnd((FunctionDecl) returnType.getRef(), cgen)
        }*/
        
    }    
    
}

