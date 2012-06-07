import structs/[List, ArrayList, HashMap]
import ../../middle/[ClassDecl, FunctionDecl, VariableDecl, TypeDecl,
        Type, Node, InterfaceDecl, InterfaceImpl, CoverDecl]
import Skeleton, FunctionDeclWriter, VersionWriter

ClassDeclWriter: abstract class extends Skeleton {

    CLASS_NAME := static const "lang_core__Class"
    OBJECT_NAME := static const "lang_core__Object"

    write: static func ~_class (this: Skeleton, cDecl: ClassDecl) {

        //printf(" << Writing class decl %s with version %s\n", cDecl toString(), cDecl getVersion() ? cDecl getVersion() toString() : "(nil)")

        if(cDecl isMeta) {

            current = hw
            if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
            writeObjectStruct(this, cDecl)
            if(cDecl getVersion()) VersionWriter writeEnd(this)

            current = cw
            if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())

            if(cDecl getNonMeta() instanceOf?(InterfaceImpl)) {
                // for interfaces
                current = fw
                if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
                writeClassGettingPrototype(this, cDecl)
                if(cDecl getVersion()) VersionWriter writeEnd(this)

            } else {
                // for regular classes
                current = fw
                if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
                writeMemberFuncPrototypes(this, cDecl)
                if(cDecl getVersion()) VersionWriter writeEnd(this)

                current = cw
                writeInstanceVirtualFuncs(this, cDecl)
                writeStaticFuncs(this, cDecl)
                writeInstanceImplFuncs(this, cDecl)
            }

            // don't write class-getting functions of extern covers - it hurts
            if(cDecl getNonMeta() == null || !cDecl getNonMeta() instanceOf?(CoverDecl) || !(cDecl getNonMeta() as CoverDecl isExtern() || cDecl getNonMeta() as CoverDecl isAddon())) {
                current = cw
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

    writeObjectStruct: static func (this: Skeleton, cDecl: ClassDecl) {

        current nl(). app("struct _"). app(cDecl underName()). app(' '). openBlock()

        if (cDecl name != "Object" && cDecl getSuperRef() != null) {
            current nl(). app("struct _"). app(cDecl getSuperRef() underName()). app(" __super__;")
        }

        for(vDecl in cDecl variables) {
            // ignore extern and virtual variables (usually properties)
            if(vDecl isExtern() || vDecl isVirtual()) continue;

            current nl()
            vDecl getType() write(current, vDecl getFullName())
            current app(';')
        }

        // Now write all virtual functions prototypes in the class struct
        for (fDecl in cDecl functions) {

            if(fDecl isExtern()) continue // extern functions are just aliases for C funcs

            if(fDecl isFinal()) continue // final functions are not virtual, since they can't be overriden

            if(cDecl getSuperRef() != null) {
                superDecl : FunctionDecl = null
                finalScore := 0
                superDecl = cDecl getSuperRef() getFunction(fDecl name, fDecl suffix, finalScore&)

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
    writeFunctionDeclPointer: static func (this: Skeleton, fDecl: FunctionDecl, doName: Bool) {

        current app((fDecl hasReturn() ? fDecl getReturnType() : Type voidType()) as Node)

        current app(" (*")
        if(doName) FunctionDeclWriter writeSuffixedName(this, fDecl)
        current app(")")

        FunctionDeclWriter writeFuncArgs(this, fDecl, ArgsWriteMode TYPES_ONLY, null);

    }

    /** Write the prototypes of member functions */
    writeMemberFuncPrototypes: static func (this: Skeleton, cDecl: ClassDecl) {
        writeClassGettingPrototype(this, cDecl)

        for(fDecl: FunctionDecl in cDecl functions) {

            if(fDecl isExtern()) {
                // write the #define
                FunctionDeclWriter write(this, fDecl)
            }

            if(fDecl isExternWithName() && !fDecl isProto()) {
                continue
            }

            current nl()
            if(fDecl isProto()) current app("extern ")
            FunctionDeclWriter writeFuncPrototype(this, fDecl, null)
            current app(';')

            if(!fDecl isStatic() && !fDecl isAbstract() && !fDecl isFinal()) {
                current nl()
                FunctionDeclWriter writeFuncPrototype(this, fDecl, "_impl")
                current app(';')
            }

        }

    }

    writeStaticFuncs: static func (this: Skeleton, cDecl: ClassDecl) {

        for (decl: FunctionDecl in cDecl functions) {

            if (!decl isStatic() || decl isProto() || decl isAbstract()) continue

            if(decl isExternWithName()) {
                FunctionDeclWriter write(this, decl)
                continue
            }

            current nl()
            FunctionDeclWriter writeFuncPrototype(this, decl);

            current app(' '). openBlock(). nl()

            if(decl getName() == ClassDecl LOAD_FUNC_NAME) {
                superRef := cDecl getSuperRef()
                finalScore: Int
                superLoad := superRef getFunction(ClassDecl LOAD_FUNC_NAME, null, null, finalScore&)
                if(superLoad) {
                    FunctionDeclWriter writeFullName(this, superLoad)
                    current app("();")
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

    writeInstanceVirtualFuncs: static func (this: Skeleton, cDecl: ClassDecl) {

        for(fDecl: FunctionDecl in cDecl functions) {

            if (!fDecl isVirtual()) {
                continue
            }

            current nl(). nl()

            FunctionDeclWriter writeFuncPrototype(this, fDecl)
            current app(" { ")

            baseClass := cDecl getBaseClass(fDecl)

            if (fDecl hasReturn()) {
                current app("return ("). app(fDecl returnType). app(") ")
            }

            if(cDecl getNonMeta() instanceOf?(InterfaceDecl)) {
                current app("this.impl->")
            } else {
                current app("(("). app(baseClass underName()). app(" *)"). app("(("). app(This OBJECT_NAME). app(" *)this)->class)->")
            }
            FunctionDeclWriter writeSuffixedName(this, fDecl)
            FunctionDeclWriter writeFuncArgs(this, fDecl, ArgsWriteMode VALUES_ONLY, baseClass)

            current app("; }")
        }

    }

    writeInstanceImplFuncs: static func (this: Skeleton, cDecl: ClassDecl) {

        if(cDecl getName() contains?("Glass")) "writing instance impl funcs for %s" printfln(cDecl toString())

        // Non-static (ie  instance) functions
        for (decl: FunctionDecl in cDecl functions) {
            if (decl isStatic() || decl isAbstract() || decl isExternWithName()) {
                continue
            }

            current nl(). nl()
            FunctionDeclWriter writeFuncPrototype(this, decl, (decl isFinal()) ? null : "_impl")
            current app(' '). openBlock()
            
            if(decl getName() == ClassDecl DEFAULTS_FUNC_NAME) {
                nonMeta := cDecl getNonMeta()
                superType := nonMeta getSuperType()
                superRef  := nonMeta getSuperRef()

                if(superType != null && superType getTypeArgs() != null) {
                    j := 0
                    for(typeArg in superType getTypeArgs()) {
                        refTypeArg := superRef getTypeArgs() get(j)

                        shouldAssign := true
                        for(candidate in nonMeta getTypeArgs()) {
                            if(candidate getName() == typeArg getName()) {
                                // no need to assign it, it just makes the type arguments transitive
                                shouldAssign = false
                                break
                            }
                        }

                        if(!shouldAssign) continue

                        realOwner := cDecl getVariable(refTypeArg getName()) getOwner()
                        current nl(). app("(("). app(realOwner getInstanceType()). app(") this)->"). app(refTypeArg getName()). app(" = (void*) "). app(typeArg). app(';')

                        j += 1
                    }
                }

                if(cDecl getSuperRef()) {
                    finalScore: Int
                    superDefaults := cDecl getSuperRef() getFunction(ClassDecl DEFAULTS_FUNC_NAME, null, null, finalScore&)
                    if(superDefaults) {
                        current nl()
                        FunctionDeclWriter writeFullName(this, superDefaults)
                        current app("_impl(("). app(superDefaults owner getInstanceType()). app(") this);")
                    }
                }

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

    getClassType: static func (cDecl: ClassDecl) -> ClassDecl {
        if(cDecl getNonMeta() != null && cDecl getNonMeta() instanceOf?(InterfaceImpl)){
            cDecl getSuperRef() as ClassDecl
        } else {
            cDecl
        }
    }

    writeClassGettingPrototype: static func (this: Skeleton, cDecl: ClassDecl) {
        realDecl := getClassType(cDecl)
        current nl(). app(realDecl underName()). app(" *"). app(cDecl getNonMeta() getFullName()). app("_class();")
    }

    writeClassGettingFunction: static func (this: Skeleton, cDecl: ClassDecl) {

        realDecl := getClassType(cDecl)
        underName := realDecl underName()

        current nl(). nl(). app(underName). app(" *"). app(cDecl getNonMeta() getFullName()). app("_class()"). openBlock(). nl()

        isCover := cDecl getNonMeta() instanceOf?(CoverDecl)
        if (isCover) {
            // FOR COVERS
            current app("static "). app(This CLASS_NAME). app("* classPtr = NULL;"). nl()

            current app("if (!classPtr) "). openBlock(). nl()

            current app("classPtr = (void*) "). app(This CLASS_NAME). app("_forCover(")

            // instanceSize
            cDecl getNonMeta() writeSize(current, true) 

            // size
            current app(", ")
            cDecl getNonMeta() writeSize(current, false)
            current app(");")

            // super
            current nl(). app("classPtr->super = ")
            current app(" ("). app(This CLASS_NAME). app("*) "). app(cDecl getNonMeta() getSuperRef() getFullName()). app("_class()")
            current app(";")

            // name needs to be done separately because of String constructor
            current nl(). app("classPtr->name = ")
            writeStringLiteral(realDecl getNonMeta() name, false)
            current app(";")


            current closeBlock();
            current nl(). app("return (void*) classPtr;"). closeBlock()
        } else {
            // FOR NON-COVERS
            current app("static int __done__ = 0;"). nl()
            current app("static "). app(underName). app(" class = ")


            current nl()
            writeClassStructInitializers(this, realDecl, cDecl, ArrayList<FunctionDecl> new(), true)
            current app(';')

            current nl(). app(This CLASS_NAME). app(" *classPtr = ("). app(This CLASS_NAME). app(" *) &class;")
            current nl(). app("if(!__done__++)"). openBlock()

            current nl(). app("classPtr->instanceSize = ")
            cDecl getNonMeta() writeSize(current, true) 
            current app(";")

            current nl(). app("classPtr->size = ")
            cDecl getNonMeta() writeSize(current, false) 
            current app(";")

            if (cDecl getNonMeta() getSuperRef()) {
                current nl(). app("classPtr->super = ("). app(This CLASS_NAME). app("*) "). app(cDecl getNonMeta() getSuperRef() getFullName()). app("_class();")
            }

            current nl(). app("classPtr->name = ")
            writeStringLiteral(realDecl getNonMeta() name, false)
            current app(";")

            current closeBlock()
            current nl(). app("return &class;"). closeBlock()
        }
    }

    /**
     * Write class initializers
     * @param parentClass
     */
    writeClassStructInitializers: static func (this: Skeleton, parentClass: ClassDecl,
        realClass: ClassDecl, done: List<FunctionDecl>, root: Bool) {

        current openBlock(). nl()

        if (parentClass name equals?("Class")) {
            current app("{ NULL }, ") // class
        } else {
            writeClassStructInitializers(this, parentClass getSuperRef() as ClassDecl, realClass, done, false)
        }

        for(vDecl in parentClass variables) {
            // ignore extern and virtual variables (usually properties)
            if(vDecl isExtern() || vDecl isVirtual()) continue;

            current nl(). app(" (")
            vDecl getType() write(current, null)
            current app(") 0,")
        }

        if(parentClass != realClass ||
           realClass getNonMeta() == null ||
           !realClass getNonMeta() instanceOf?(InterfaceDecl)) {
            for (parentDecl: FunctionDecl in parentClass functions) {
                if(done contains?(parentDecl)) {
                    continue
                }

                realDecl : FunctionDecl = null
                if(realClass != parentClass) {
                    finalScore: Int
                    realDecl = realClass getFunction(parentDecl name, parentDecl suffix ? parentDecl suffix : "", null, true, finalScore&)

                    if(realDecl != parentDecl) {
                        if(done contains?(realDecl)) {
                            continue
                        }
                        done add(realDecl)
                    }
                }

                if (parentDecl isFinal() || parentDecl isExtern() || (realDecl != null && realDecl isExtern())) {
                    continue // skip it.
                }

                if (parentDecl isStatic() && parentDecl isAbstract()) {
                    continue // abstract static funcs aren't written in classes
                }

                if (parentDecl isStatic()) {
                    writeDesignatedInit(this, parentDecl, realDecl, false) // impl = false
                } else if(realDecl == null && parentDecl isAbstract()) {
                    current nl(). app("NULL, ")
                } else {
                    writeDesignatedInit(this, parentDecl, realDecl, true) // impl = true
                }
            }
        }

        if (parentClass != realClass &&
            parentClass getNonMeta() != null &&
            parentClass getNonMeta() instanceOf?(InterfaceDecl) &&
            realClass getNonMeta() instanceOf?(InterfaceImpl)) {

            interfaceImpl := realClass getNonMeta() as InterfaceImpl
            for(alias: FunctionAlias in interfaceImpl getAliases()) {
                current nl(). app(" (void*) ")
                FunctionDeclWriter writeFullName(this, alias value)
                if(!alias value isFinal() && !alias value isAbstract()) current app("_impl")
                current app(",")
            }
        }

        current closeBlock()
        if (!root)
            current app(',')
    }

    writeDesignatedInit: static func (this: Skeleton, parentDecl, realDecl: FunctionDecl, impl: Bool) {

        if(realDecl != null && realDecl isAbstract) return

        current nl(). app(" (void*) ")

        decl := realDecl ? realDecl : parentDecl
        FunctionDeclWriter writeFullName(this, decl)
        if(!decl isExternWithName() && impl) current app("_impl")
        current app(',')

    }

    writeStructTypedef: static func (this: Skeleton, cDecl: ClassDecl) {

        structName := cDecl underName()
        if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
        current nl(). app("struct _"). app(structName). app(";")
        current nl(). app("typedef struct _"). app(structName). app(" "). app(structName). app(";")
        if(cDecl getVersion()) VersionWriter writeEnd(this)
    }

}
