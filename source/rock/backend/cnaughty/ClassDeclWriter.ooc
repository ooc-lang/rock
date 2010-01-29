import structs/[List, ArrayList, HashMap]
import ../../middle/[ClassDecl, FunctionDecl, VariableDecl, TypeDecl, Type, Node]
import Skeleton, FunctionDeclWriter, CGenerator

ClassDeclWriter: abstract class extends CGenerator {

    LANG_PREFIX := static const "lang__";
    CLASS_NAME := static const LANG_PREFIX + "Class";
    
    write: static func ~_class (this: This, cDecl: ClassDecl) {

        //printf(" << Writing class decl %s\n", cDecl toString())
                
        if(cDecl isMeta) {
            
            current = hw
            writeObjectStruct(this, cDecl)
            
            current = fw
            writeMemberFuncPrototypes(this, cDecl)
            
            current = cw
            writeInstanceImplFuncs(this, cDecl)
            writeClassGettingFunction(this, cDecl)
            writeInstanceVirtualFuncs(this, cDecl)
            writeStaticFuncs(this, cDecl)
            
        } else {
            
            current = hw
            writeObjectStruct(this, cDecl)
        
        }
        
    }
    
    writeObjectStruct: static func (this: This, cDecl: ClassDecl) {
        
        current nl(). app("struct _"). app(cDecl underName()). app(' '). openBlock(). nl()

        if (!(cDecl name equals("Object"))) {
            current app("struct _"). app(cDecl getSuperRef() underName()). app(" __super__;")
        }
        
        for(vName: String in cDecl variables keys) {
            // FIXME should figure out the type of vDecl by itself. Generics again, grr.
            vDecl := cDecl variables get(vName) as VariableDecl
            current nl(). app(vDecl). app(';')
        }
        
        // Now write all virtual functions prototypes in the class struct
        for (fDecl: FunctionDecl in cDecl functions) {
            
            if(cDecl getSuperRef() != null) {
                superDecl : FunctionDecl = null
                superDecl = cDecl getSuperRef() getFunction(fDecl name, fDecl suffix)
                // don't write the function if it was declared in the parent
                if(superDecl != null && !fDecl name equals("init")) {
                    //printf("Already declared in super %s, skipping (superDecl = %s)\n", cDecl getSuperRef() toString(), superDecl toString())
                    continue
                }
            }
            
            current nl()
            writeFunctionDeclPointer(this, fDecl, true)
            current app(';')
        }
        
        // And all static variables
        for (vDecl: VariableDecl in cDecl variables) {
            // skip non-static and extern variables
            if (!vDecl isStatic || vDecl isExtern) continue
                
            current nl(). app(vDecl). app(';')
        }
        
        current closeBlock(). app(';'). nl(). nl()
        
    }
    
    /** Write a function declaration's pointer */
    writeFunctionDeclPointer: static func (this: This, fDecl: FunctionDecl, doName: Bool) {
        
        current app((fDecl hasReturn() ? fDecl getReturnType() : voidType) as Node)
        
        current app(" (*")
        if(doName) FunctionDeclWriter writeSuffixedName(this, fDecl)
        current app(")")
        
        FunctionDeclWriter writeFuncArgs(this, fDecl, ArgsWriteModes TYPES_ONLY, null);
        
    }
   
    /** Write the prototypes of member functions */
    writeMemberFuncPrototypes: static func (this: This, cDecl: ClassDecl) {

        current nl(). app(cDecl underName()). app(" *"). app(cDecl getNonMeta() name). app("_class();")

        for(fDecl: FunctionDecl in cDecl functions) {
            
            if(fDecl isExtern() && !fDecl externName isEmpty()) {
                continue
            }
            
            current nl()
            FunctionDeclWriter writeFuncPrototype(this, fDecl, null)
            current app(';')
            if(!fDecl isStatic && !fDecl isAbstract && !fDecl isFinal) {
                current nl()
                FunctionDeclWriter writeFuncPrototype(this, fDecl, "_impl")
                current app(';')
            }
            
        }
        
    }

    writeStaticFuncs: static func (this: This, cDecl: ClassDecl) {

		for (fDecl: FunctionDecl in cDecl functions) {

			if (!fDecl isStatic || (fDecl isExternWithName())) {
				if(fDecl isExternWithName()) {
					FunctionDeclWriter write(this, fDecl)
				}
				continue
			}

            current nl()
			FunctionDeclWriter writeFuncPrototype(this, fDecl);
            
			current app(' '). openBlock(). nl()
            for(stat in fDecl body) {
                writeLine(stat)
            }
            current closeBlock()

		}
	}
    
    writeInstanceVirtualFuncs: static func (this: This, cDecl: ClassDecl) {

		for(fDecl: FunctionDecl in cDecl functions) {

			if (fDecl isStatic || fDecl isFinal) {
				continue
            }

			current nl(). nl()
			FunctionDeclWriter writeFuncPrototype(this, fDecl)
			current app(' '). openBlock(). nl()

            baseClass := cDecl getBaseClass(fDecl)
			if (fDecl hasReturn()) {
				current app("return ("). app(fDecl returnType). app(")")
			}
			current app("(("). app(baseClass underName()). app(" *)((lang__Object *)this)->class)->")
            FunctionDeclWriter writeSuffixedName(this, fDecl)
			FunctionDeclWriter.writeFuncArgs(this, fDecl, ArgsWriteModes NAMES_ONLY, baseClass);
			current app(";"). closeBlock()

		}
	}
    
    writeInstanceImplFuncs: static func (this: This, cDecl: ClassDecl) {

        // Non-static (ie  instance) functions
        for (decl: FunctionDecl in cDecl functions) {
            if (decl isStatic || decl isAbstract || (decl isExtern() && !decl externName isEmpty())) {
                continue
            }
            
            current nl(). nl()
            FunctionDeclWriter writeFuncPrototype(this, decl, decl isFinal ? null : "_impl")
            current app(' '). openBlock(). nl()
            
            for(stat in decl body) {
                writeLine(stat)
            }
            current closeBlock()
        }

    }

    writeClassGettingFunction: static func (this: This, cDecl: ClassDecl) {

        current nl(). nl(). app(cDecl underName()). app(" *"). app(cDecl getNonMeta() getName()). app("_class()"). openBlock(). nl()
        
        if (cDecl getNonMeta() getSuperRef()) {
            current app("static "). app(LANG_PREFIX). app("Bool __done__ = false;"). nl()
        }
        current app("static "). app(cDecl underName()). app(" class = "). nl()
        
        writeClassStructInitializers(this, cDecl, cDecl, ArrayList<FunctionDecl> new())
        
        current app(';')
        if (cDecl getNonMeta() getSuperRef()) {
            current nl(). app(CLASS_NAME). app(" *classPtr = ("). app(CLASS_NAME). app(" *) &class;")
            current nl(). app("if(!__done__)"). openBlock().
                    nl(). app("classPtr->super = ("). app(CLASS_NAME). app("*) "). app(cDecl getNonMeta() getSuperRef() getName()). app("_class();").
                    nl(). app("__done__ = true;").
            closeBlock()
        }

        current nl(). app("return &class;"). closeBlock()
    }

    /**
     * Write class initializers
     * @param parentClass 
     */
    writeClassStructInitializers: static func (this: This, parentClass: ClassDecl,
        realClass: ClassDecl, done: List<FunctionDecl>) {

        current openBlock(). nl()

        if (parentClass name equals("Class")) {
            current app(".instanceSize = "). app("sizeof("). app(realClass getNonMeta() underName()). app("),").
              nl() .app(".size = "). app("sizeof(void*),").
              nl() .app(".name = "). app('"'). app(realClass getNonMeta() name). app("\",")
        } else {
            writeClassStructInitializers(this, parentClass getSuperRef(), realClass, done)
        }

        for (parentDecl: FunctionDecl in parentClass functions) {
            if(done contains(parentDecl) && !parentDecl name equals("init")) {
                continue
            }
            
            realDecl : FunctionDecl = null
            if(realClass != parentClass && !parentDecl name equals("init")) {
                realDecl = realClass getFunction(parentDecl name, parentDecl suffix, null, true, 0, null)
                if(realDecl != parentDecl) {
                    if(done contains(realDecl)) {
                        continue
                    }
                    done add(realDecl)
                }
            }
            
            if (parentDecl isStatic || parentDecl isFinal || (realDecl == null && parentDecl isAbstract)) {
                writeDesignatedInit(this, parentDecl, realDecl, false)
            } else {
                writeDesignatedInit(this, parentDecl, realDecl, true)
            }

        }

        current closeBlock()
        if (realClass != parentClass)
            current app(',')
    }
    
    writeDesignatedInit: static func (this: This, parentDecl, realDecl: FunctionDecl, impl: Bool) {

        if(realDecl != null && realDecl isAbstract) return
            
        current nl(). app('.')
        FunctionDeclWriter writeSuffixedName(this, parentDecl)
        current app(" = ")
        
        if(realDecl != null || parentDecl isExtern()) {
            current app("(")
            writeFunctionDeclPointer(this, parentDecl, false)
            current app(") ")
        }

        FunctionDeclWriter writeFullName(this, realDecl ? realDecl : parentDecl)
        if(impl) current app("_impl")
        current app(',')

    }
    
    writeStructTypedef: static func (this: This, structName: String) {
        
		current nl(). app("struct _"). app(structName). app(";")
		current nl(). app("typedef struct _"). app(structName). app(" "). app(structName). app(";")
        
	}
    
}

