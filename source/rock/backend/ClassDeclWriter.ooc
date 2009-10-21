import ../middle/[ClassDecl, FunctionDecl, VariableDecl, TypeDecl, Type]
import Skeleton, FunctionDeclWriter

ClassDeclWriter: abstract class extends Skeleton {

	LANG_PREFIX := static const "lang__";
	CLASS_NAME := static const LANG_PREFIX + "Class";
    
    write: static func ~_class (this: This, cDecl: ClassDecl) {
        current = hw
        writeObjectStruct(this, cDecl)
        writeClassStruct(this, cDecl)
    }
    
    writeObjectStruct: static func (this: This, cDecl: ClassDecl) {
        
        current nl(). app("struct _"). app(cDecl underName()). openBlock()

        if(cDecl isClassClass()) {
            current app(CLASS_NAME). app(" *class;")
        } else if (!cDecl isObjectClass()) {
            current app("struct _"). app(cDecl superRef() ? cDecl superRef() underName() : "FIXME"). app(" __super__;")
        }
        
        for(vName: String in cDecl variables keys) {
            // FIXME should figure out the type of vDecl by itself. Generics again, grr.
            vDecl := cDecl variables get(vName) as VariableDecl
            if(vDecl isStatic) continue
            current nl(). app(vDecl). app(';')
        }
        
        current closeBlock(). nl(). nl()
        
	}
    
    writeClassStruct: static func (this: This, cDecl: ClassDecl) {

        current nl(). app("struct _"). app(cDecl underName()). app("Class"). openBlock()

        if(cDecl isRootClass()) {
			current app("struct _"). app(CLASS_NAME). app(" __super__;")
		} else {
			current app("struct _"). app(cDecl superRef() ? cDecl superRef() underName() : "FIXME"). app("Class __super__;")
		}

		/* Now write all virtual functions prototypes in the class struct */
        for (fDecl: FunctionDecl in cDecl functions) {
            if(cDecl superRef()) {
                superDecl := cDecl superRef() getFunction(fDecl name, fDecl suffix)
                // don't write the function if it was declared in the parent
                if(superDecl && !fDecl name equals("init")) continue
            }
            
            current nl()
            writeFunctionDeclPointer(this, fDecl, true)
            current app(';')
        }
		
        /* And all static variables */
		for (vDecl: VariableDecl in cDecl variables) {
            // skip non-static and extern variables
			if (!vDecl isStatic || vDecl isExtern) continue
                
			current nl(). app(vDecl). app(';')
		}
		
		current closeBlock(). app(';'). nl(). nl()
	}
    
    /** Write a function declaration's pointer */
    writeFunctionDeclPointer: static func (this: This, fDecl: FunctionDecl, doName: Bool) {
        
        current app(fDecl hasReturn() ? fDecl returnType : voidType)
		
		current app(" (*")
		if(doName) FunctionDeclWriter writeSuffixedName(this, fDecl)
		current app(")")
		
		FunctionDeclWriter writeFuncArgs(this, fDecl, ArgsWriteModes TYPES_ONLY, null);
        
	}
    
}

