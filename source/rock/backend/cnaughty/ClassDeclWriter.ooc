import structs/[List, ArrayList, HashMap]
import ../../middle/[ClassDecl, FunctionDecl, VariableDecl, TypeDecl,
        Type, Node, InterfaceDecl, InterfaceImpl, CoverDecl]
import Skeleton, FunctionDeclWriter, CGenerator, VersionWriter

ClassDeclWriter: abstract class extends CGenerator {

    LANG_PREFIX := static const "lang_types__"
    CLASS_NAME := static const This LANG_PREFIX + "Class"
    
    write: static func ~_class (this: This, cDecl: ClassDecl) {

        //printf(" << Writing class decl %s with version %s\n", cDecl toString(), cDecl getVersion() ? cDecl getVersion() toString() : "(nil)")
                
        if(cDecl isMeta) {
            
            current = hw
            if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
            writeObjectStruct(this, cDecl)
            if(cDecl getVersion()) VersionWriter writeEnd(this)
            
            //TODO: split into InterfaceImplWriter ?
            if(!cDecl getNonMeta() instanceOf(InterfaceImpl)) {
                current = fw
                if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
                writeMemberFuncPrototypes(this, cDecl)
                if(cDecl getVersion()) VersionWriter writeEnd(this)
            
                current = cw
                if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
                writeInstanceImplFuncs(this, cDecl)
                writeInstanceVirtualFuncs(this, cDecl)
                writeStaticFuncs(this, cDecl)
            } else {
                current = cw
                if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
            }

            // don't write class-getting functions of extern covers - it hurts
            if(cDecl getNonMeta() == null || !cDecl getNonMeta() instanceOf(CoverDecl) || !cDecl getNonMeta() as CoverDecl isExtern()) {
                writeClassGettingFunction(this, cDecl)
            }
            
            if(cDecl getVersion()) VersionWriter writeEnd(this)
            
            for(interfaceDecl in cDecl getNonMeta() getInterfaceDecls()) {
                write(this, interfaceDecl getMeta())
            }
        
            
        } else {
            
            current = hw
            if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
            writeObjectStruct(this, cDecl)
            if(cDecl getVersion()) VersionWriter writeEnd(this)
            
            for(interfaceDecl in cDecl getInterfaceDecls()) {
                write(this, interfaceDecl)
            }
        
        }
        
    }
    
    writeObjectStruct: static func (this: This, cDecl: ClassDecl) {
        
        current nl(). app("struct _"). app(cDecl underName()). app(' '). openBlock()

        if (cDecl name != "Object" && cDecl getSuperRef() != null) {
            current nl(). app("struct _"). app(cDecl getSuperRef() underName()). app(" __super__;")
        }
        
        for(vDecl in cDecl variables) {
            if(vDecl isExtern()) continue;
            
            current nl(). app(vDecl getType()). app(" "). app(vDecl getName()). app(';')
        }
        
        // Now write all virtual functions prototypes in the class struct
        for (fDecl in cDecl functions) {
            
            if(cDecl getSuperRef() != null) {
                superDecl : FunctionDecl = null
                superDecl = cDecl getSuperRef() lookupFunction(fDecl name, fDecl suffix)
                // don't write the function if it was declared in the parent
                if(superDecl != null) {
                    //printf("Already declared in super %s, skipping (superDecl = %s)\n", cDecl getSuperRef() toString(), superDecl toString())
                    continue
                }
            }
            
            current nl()
            writeFunctionDeclPointer(this, fDecl, true)
            current app(';')
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

        current nl(). app(cDecl underName()). app(" *"). app(cDecl getNonMeta() getFullName()). app("_class();")

        for(fDecl: FunctionDecl in cDecl functions) {
            
            if(fDecl isExtern() && !fDecl externName isEmpty()) {
                continue
            }
            
            current nl()
            FunctionDeclWriter writeFuncPrototype(this, fDecl, null)
            current app(';')
            if(!fDecl isStatic() && !fDecl isAbstract() && !fDecl isFinal()) {
                current nl()
                FunctionDeclWriter writeFuncPrototype(this, fDecl, "_impl")
                current app(';')
            }
            
        }
        
    }

    writeStaticFuncs: static func (this: This, cDecl: ClassDecl) {

		for (decl: FunctionDecl in cDecl functions) {

			if (!decl isStatic() || decl isExternWithName()) {
				if(decl isExternWithName()) {
					FunctionDeclWriter write(this, decl)
				}
				continue
			}

            current nl()
			FunctionDeclWriter writeFuncPrototype(this, decl);
            
			current app(' '). openBlock()
            
            if(decl getName() == ClassDecl LOAD_FUNC_NAME) {
                superRef := cDecl getSuperRef()
                finalScore: Int
            	superLoad := superRef getFunction(ClassDecl LOAD_FUNC_NAME, null, null, finalScore&)
            	if(superLoad) {
					FunctionDeclWriter writeFullName(this, superLoad)
					current app("_impl(("). app(superLoad owner getInstanceType()). app(") this);")
            	}
            	for(vDecl in cDecl variables) {
					if(vDecl getExpr() == null) continue
					current nl(). app(cDecl getNonMeta() underName()). app("_class()->"). app(vDecl getName()). app(" = "). app(vDecl getExpr()). app(';')
				}
            }
            
            for(stat in decl body) {
                writeLine(stat)
            }
            current closeBlock()

		}
	}
    
    writeInstanceVirtualFuncs: static func (this: This, cDecl: ClassDecl) {

		for(fDecl: FunctionDecl in cDecl functions) {

			if (fDecl isStatic() || fDecl isFinal()) {
				continue
            }

			current nl(). nl()
			FunctionDeclWriter writeFuncPrototype(this, fDecl)
			current app(' '). openBlock(). nl()

            baseClass := cDecl getBaseClass(fDecl)
			if (fDecl hasReturn()) {
				current app("return ("). app(fDecl returnType). app(") ")
			}
            if(cDecl getNonMeta() instanceOf(InterfaceDecl)) {
                current app("this.impl->")
            } else {
                current app("(("). app(baseClass underName()). app(" *)"). app("((lang_types__Object *)this)->class)->")
            }
            FunctionDeclWriter writeSuffixedName(this, fDecl)
			FunctionDeclWriter writeFuncArgs(this, fDecl, ArgsWriteModes NAMES_ONLY, baseClass)
			current app(";"). closeBlock()

		}
	}
    
    writeInstanceImplFuncs: static func (this: This, cDecl: ClassDecl) {

        // Non-static (ie  instance) functions
        for (decl: FunctionDecl in cDecl functions) {
            if (decl isStatic() || decl isAbstract() || decl isExternWithName()) {
                continue
            }
            
            current nl(). nl()
            FunctionDeclWriter writeFuncPrototype(this, decl, decl isFinal ? null : "_impl")
            current app(' '). openBlock()

            if(decl getName() == ClassDecl DEFAULTS_FUNC_NAME) {
            	superRef := cDecl getSuperRef()
                finalScore: Int
            	superDefaults := superRef getFunction(ClassDecl DEFAULTS_FUNC_NAME, null, null, finalScore&)
            	if(superDefaults) {
					FunctionDeclWriter writeFullName(this, superDefaults)
					current app("_impl(("). app(superDefaults owner getInstanceType()). app(") this);")
            	}
            	nonMeta := cDecl getNonMeta()
				for(vDecl in nonMeta variables) {
					if(vDecl getExpr() == null) continue
					current nl(). app("this->"). app(vDecl getName()). app(" = "). app(vDecl getExpr()). app(';')
				}
            }
            
            for(stat in decl body) {
                writeLine(stat)
            }
            current closeBlock()
        }

    }

    writeClassGettingFunction: static func (this: This, cDecl: ClassDecl) {

        isInterface := (cDecl getNonMeta() != null && cDecl getNonMeta() instanceOf(InterfaceImpl)) as Bool
        underName := isInterface ? cDecl getSuperRef() underName() : cDecl underName()

        current nl(). nl(). app(underName). app(" *"). app(cDecl getNonMeta() getFullName()). app("_class()"). openBlock(). nl()
        
        if (cDecl getNonMeta() getSuperRef()) {
            current app("static "). app(This LANG_PREFIX). app("Bool __done__ = false;"). nl()
        }
        current app("static "). app(underName). app(" class = "). nl()
        
        writeClassStructInitializers(this, isInterface ? cDecl getSuperRef() : cDecl, cDecl, ArrayList<FunctionDecl> new(), true)
        
        current app(';')
        if (cDecl getNonMeta() getSuperRef()) {
            current nl(). app(This CLASS_NAME). app(" *classPtr = ("). app(This CLASS_NAME). app(" *) &class;")
            current nl(). app("if(!__done__)"). openBlock().
                    nl(). app("classPtr->super = ("). app(This CLASS_NAME). app("*) "). app(cDecl getNonMeta() getSuperRef() getFullName()). app("_class();").
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
        realClass: ClassDecl, done: List<FunctionDecl>, root: Bool) {

        current openBlock(). nl()

        if (parentClass name equals("Class")) {
            current app(".instanceSize = "). app("sizeof("). app(realClass getNonMeta() underName()). app("),").
              nl() .app(".size = "). app("sizeof(void*),").
              nl() .app(".name = "). app('"'). app(realClass getNonMeta() name). app("\",")
        } else {
            writeClassStructInitializers(this, parentClass getSuperRef(), realClass, done, false)
        }

        if(parentClass != realClass ||
           realClass getNonMeta() == null ||
           !realClass getNonMeta() instanceOf(InterfaceDecl)) {
            for (parentDecl: FunctionDecl in parentClass functions) {
                if(done contains(parentDecl)) {
                    continue
                }
                
                realDecl : FunctionDecl = null
                if(realClass != parentClass) {
                    realDecl = realClass getFunction(parentDecl name, parentDecl suffix ? parentDecl suffix : "", null, true)
                    
                    if(realDecl != parentDecl) {
                        if(done contains(realDecl)) {
                            continue
                        }
                        done add(realDecl)
                    }
                }
                
                if (parentDecl isFinal()) continue; // skip it.
                
                if (parentDecl isStatic() || (realDecl == null && parentDecl isAbstract())) {
                    writeDesignatedInit(this, parentDecl, realDecl, false)
                } else {
                    writeDesignatedInit(this, parentDecl, realDecl, true)
                }
            }
        }
        
        if (parentClass != realClass &&
            parentClass getNonMeta() != null &&
            parentClass getNonMeta() instanceOf(InterfaceDecl) &&
            realClass getNonMeta() instanceOf(InterfaceImpl)) {
            
            interfaceImpl := realClass getNonMeta() as InterfaceImpl
            for(alias: FunctionAlias in interfaceImpl getAliases()) {
                current nl(). app('.'). app(alias key getName()). app(" = (void*) ")
                FunctionDeclWriter writeFullName(this, alias value)
                if(!alias value isFinal()) current app("_impl")
                current app(",")
            }
        }

        current closeBlock()
        if (!root)
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

		decl := realDecl ? realDecl : parentDecl
        FunctionDeclWriter writeFullName(this, decl)
        if(!decl isExternWithName() && impl) current app("_impl")
        current app(',')

    }
    
    writeStructTypedef: static func (this: This, cDecl: ClassDecl) {

        structName := cDecl underName()
        if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
		current nl(). app("struct _"). app(structName). app(";")
		current nl(). app("typedef struct _"). app(structName). app(" "). app(structName). app(";")
        if(cDecl getVersion()) VersionWriter writeEnd(this)
        
	}
    
}

