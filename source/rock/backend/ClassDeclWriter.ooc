import structs/[List, ArrayList, HashMap]
import ../middle/[ClassDecl, FunctionDecl, VariableDecl, TypeDecl, Type, Node, Line]
import Skeleton, FunctionDeclWriter

ClassDeclWriter: abstract class extends Skeleton {

    LANG_PREFIX := static const "lang__";
    CLASS_NAME := static const LANG_PREFIX + "Class";
    
    write: static func ~_class (this: This, cDecl: ClassDecl) {
        
        current = fw
        writeMemberFuncPrototypes(this, cDecl)
        
        current = hw
        writeObjectStruct(this, cDecl)
        writeClassStruct(this, cDecl)
        
        current = cw
        //writeInstanceImplFuncs(this, cDecl);
        writeClassGettingFunction(this, cDecl);
        //writeInstanceVirtualFuncs(this, cDecl);
        //writeStaticFuncs(this, cDecl);
        
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
        
        current app((fDecl hasReturn() ? fDecl returnType : voidType) as Node)
        
        current app(" (*")
        if(doName) FunctionDeclWriter writeSuffixedName(this, fDecl)
        current app(")")
        
        FunctionDeclWriter writeFuncArgs(this, fDecl, ArgsWriteModes TYPES_ONLY, null);
        
    }
   
    /** Write the prototypes of member functions */
    writeMemberFuncPrototypes: static func (this: This, cDecl: ClassDecl) {

        current nl(). app(CLASS_NAME). app(" *"). app(cDecl name). app("_class();"). nl()

        for(fDecl: FunctionDecl in cDecl functions) {
            
            if(fDecl isExtern() && !fDecl externName isEmpty()) {
                continue
            }
            
            current nl()
            FunctionDeclWriter writeFuncPrototype(this, fDecl, null);
            current app(';')
            if(!fDecl isStatic && !fDecl isAbstract && !fDecl isFinal) {
                current nl()
                FunctionDeclWriter writeFuncPrototype(this, fDecl, "_impl")
                current app(';')
            }
            
        }
        current nl()
    }
    
    writeInstanceImplFuncs: static func (this: This, cDecl: ClassDecl) {

        // Non-static (ie  instance) functions
        for (decl: FunctionDecl in cDecl functions) {
            if (decl isStatic || decl isAbstract || (decl isExtern() && !decl externName isEmpty()))
                continue
            
            FunctionDeclWriter writeFuncPrototype(this, decl, decl isFinal ? null : "_impl")
            current openBlock()
            if(decl name equals(ClassDecl DEFAULTS_FUNC_NAME) && cDecl superType) {
                current nl(). app(cDecl superType getName()). app("_").
                 app(ClassDecl DEFAULTS_FUNC_NAME). app("_impl((").
                 app(cDecl superRef() underName()). app(" *) this)")
            }
            for(line: Line in decl body) {
                line accept(this)
            }
            current closeBlock()
        }

    }

    writeClassGettingFunction: static func (this: This, cDecl: ClassDecl) {

        current app(CLASS_NAME). app(" *"). app(cDecl name). app("_class()"). openBlock()
        if (cDecl superType)
            current app("static "). app(LANG_PREFIX). app("Bool __done__ = false"). nl().
                    app("static "). app(cDecl underName()). app("Class class = ")
        
        writeClassStructInitializers(this, cDecl, cDecl, ArrayList<FunctionDecl> new())
        
        current app(';')
        current nl(). app(CLASS_NAME). app(" *classPtr = ("). app(CLASS_NAME). app(" *) &class")
        if (cDecl superType) {
            current nl(). app("if(!__done__)"). openBlock().
                    nl(). app("classPtr->super = "). app(cDecl superType getName()). app("_class()").
                    nl(). app("__done__ = true").
            closeBlock()
        }

        current nl(). app("return classPtr"). closeBlock()
    }

    /**
     * Write class initializers
     * @param parentClass 
     */
    writeClassStructInitializers: static func (this: This, parentClass: ClassDecl,
        realClass: ClassDecl, done: List<FunctionDecl>) {

        current openBlock()

        if (!parentClass isRootClass() && parentClass superType) {
            writeClassStructInitializers(this, parentClass superRef(), realClass, done)
        } else {
            current openBlock().
                nl() .app(".instanceSize = "). app("sizeof("). app(realClass underName()). app("),").
                nl() .app(".size = "). app("sizeof(void*),").
                nl() .app(".name = "). app('"'). app(realClass name). app("\",").
            closeBlock(). app(',')
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
        
        if(realDecl != null) {
            current app("(")
            writeFunctionDeclPointer(this, parentDecl, false)
            current app(") ")
        }

        FunctionDeclWriter writeFullName(this, realDecl ? realDecl : parentDecl)
        if(impl) current app("_impl")
        current app(',')

    }
    
}

