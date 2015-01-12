import structs/[List, ArrayList, HashMap]
import ../../middle/[ClassDecl, FunctionDecl, VariableDecl, TypeDecl,
        Type, Node, InterfaceDecl, InterfaceImpl, CoverDecl]
import Skeleton, FunctionDeclWriter, VersionWriter

ClassDeclWriter: abstract class extends Skeleton {

    LANG_PREFIX := static const "lang_types__"
    CLASS_NAME := static const This LANG_PREFIX + "Class"

    write: static func ~_class (this: Skeleton, cDecl: ClassDecl) {

        if(cDecl isMeta) {

            current = hw
            if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
            writeObjectStruct(this, cDecl)
            if(cDecl getVersion()) VersionWriter writeEnd(this, cDecl getVersion())

            //TODO: split into InterfaceImplWriter ?
            if(!cDecl getNonMeta() instanceOf?(InterfaceImpl)) {
                current = fw
                if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
                writeMemberFuncPrototypes(this, cDecl)
                if(cDecl getVersion()) VersionWriter writeEnd(this, cDecl getVersion())

                current = cw
                if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
                writeInstanceImplFuncs(this, cDecl)
                writeInstanceVirtualFuncs(this, cDecl)
                writeStaticFuncs(this, cDecl)
            } else {
                current = fw
                if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
                writeClassGettingPrototype(this, cDecl)
                if(cDecl getVersion()) VersionWriter writeEnd(this, cDecl getVersion())

                current = cw
                if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
            }

            // don't write class-getting functions of extern covers - it hurts
            if(cDecl getNonMeta() == null || !cDecl getNonMeta() instanceOf?(CoverDecl) || !(cDecl getNonMeta() as CoverDecl isExtern() || cDecl getNonMeta() as CoverDecl isAddon())) {
                writeClassGettingFunction(this, cDecl)
            }

            if(cDecl getVersion()) VersionWriter writeEnd(this, cDecl getVersion())

            for(interfaceDecl in cDecl getNonMeta() getInterfaceDecls()) {
                write(this, interfaceDecl getMeta())
            }


        } else {

            current = hw
            if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
            writeObjectStruct(this, cDecl)
            if(cDecl getVersion()) VersionWriter writeEnd(this, cDecl getVersion())

            for(interfaceDecl in cDecl getInterfaceDecls()) {
                write(this, interfaceDecl)
            }

        }

    }

    writeObjectStruct: static func (this: Skeleton, cDecl: ClassDecl, name: String = null) {
        current nl(). app("struct ")
        if(name == null) {
            current app('_'). app(cDecl underName())
        } else {
            current app(name)
        }
        current app(' '). openBlock()

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

            if(fDecl isExtern()) continue
            if(fDecl isStatic()) continue

            if(cDecl getSuperRef() != null) {
                superDecl : FunctionDecl = null
                superDecl = cDecl getSuperRef() lookupFunction(fDecl name, fDecl getSuffixOrEmpty())
                // don't write the function if it was declared in the parent
                if(superDecl != null) {
                    // Already declared in super, skipping
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

        current app((fDecl hasReturn() ? fDecl getReturnType() : voidType) as Node)

        current app(" (*")
        if(doName) FunctionDeclWriter writeSuffixedName(this, fDecl)
        current app(")")

        FunctionDeclWriter writeFuncArgs(this, fDecl, ArgsWriteModes TYPES_ONLY, null);

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

            current = cw
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

            if (fDecl isStatic() || fDecl isFinal() || fDecl isExternWithName()) {
                continue
            }

            current nl(). nl()
            FunctionDeclWriter writeFuncPrototype(this, fDecl)
            current app(' '). openBlock(). nl()

            baseClass := cDecl getBaseClass(fDecl)
            if (fDecl hasReturn()) {
                current app("return ("). app(fDecl returnType). app(") ")
            }
            if(cDecl getNonMeta() instanceOf?(InterfaceDecl)) {
                current app("this.impl->")
            } else {
                current app("(("). app(baseClass underName()). app(" *)"). app("((lang_types__Object *)this)->class)->")
            }
            FunctionDeclWriter writeSuffixedName(this, fDecl)
            FunctionDeclWriter writeFuncArgs(this, fDecl, ArgsWriteModes NAMES_ONLY, baseClass)
            current app(";"). closeBlock()

        }
    }

    writeInstanceImplFuncs: static func (this: Skeleton, cDecl: ClassDecl) {

        // Non-static (ie  instance) functions
        for (decl: FunctionDecl in cDecl functions) {
            if (decl isStatic() || decl isAbstract() || decl isExternWithName()) {
                continue
            }

            current nl(). nl()
            FunctionDeclWriter writeFuncPrototype(this, decl, (decl isFinal()) ? null : "_impl")
            current app(' '). openBlock()

            match (decl getName()) {
                case ClassDecl DEFAULTS_FUNC_NAME || ClassDecl COVER_DEFAULTS_FUNC_NAME =>
                    writeDefaults(this, cDecl)
            }

            for(stat in decl body) {
                writeLine(stat)
            }
            current closeBlock()
        }

    }

    writeDefaults: static func (this: Skeleton, cDecl: ClassDecl) {
        meat := cDecl getNonMeta()
        superType := meat getSuperType()
        superRef  := meat getSuperRef()

        // assign super's type args
        if(superType != null && superType getTypeArgs() != null) {
            j := 0
            for(typeArg in superType getTypeArgs()) {
                refTypeArg := superRef getTypeArgs() get(j)

                shouldAssign := true
                for(candidate in meat getTypeArgs()) {
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

        // call the super's defaults func, but only for classes, not for covers
        if(cDecl getSuperRef() && meat instanceOf?(ClassDecl)) {
            finalScore: Int
            superDefaults := cDecl getSuperRef() getFunction(
                ClassDecl DEFAULTS_FUNC_NAME, null, null, finalScore&)
            if(superDefaults) {
                current nl()
                FunctionDeclWriter writeFullName(this, superDefaults)
                current app("_impl(("). app(superDefaults owner getInstanceType()). app(") this);")
            }
        }

        for(vDecl in meat variables) {
            if(vDecl getExpr() == null) continue
            current nl(). app("this->"). app(vDecl getName()). app(" = "). app(vDecl getExpr()). app(';')
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

        if (cDecl getNonMeta() getSuperRef()) {
            current app("static _Bool __done__ = false;"). nl()
        }
        current app("static "). app(underName). app(" class = "). nl()

        writeClassStructInitializers(this, realDecl, cDecl, ArrayList<FunctionDecl> new(), true)

        current app(';')
        if (cDecl getNonMeta() getSuperRef()) {
            current nl(). app(This CLASS_NAME). app(" *classPtr = ("). app(This CLASS_NAME). app(" *) &class;")
            current nl(). app("if(!__done__)"). openBlock()
            match (cDecl getNonMeta()) {
                case cd: CoverDecl =>
                    // covers don't have super classes, silly.
                    current nl(). app("classPtr->super = NULL;")
                case =>
                    current nl(). app("classPtr->super = ("). app(This CLASS_NAME). app("*) "). app(cDecl getNonMeta() getSuperRef() getFullName()). app("_class();")
            }
            current nl(). app("__done__ = true;").
                    nl(). app("classPtr->name = ")
            writeStringLiteral(realDecl getNonMeta() name)
            current app(";").
                    closeBlock()
        }

        current nl(). app("return &class;"). closeBlock()
    }

    /**
     * Write class initializers
     * @param parentClass
     */
    writeClassStructInitializers: static func (this: Skeleton, parentClass: ClassDecl,
        realClass: ClassDecl, done: List<FunctionDecl>, root: Bool) {

        current openBlock(). nl()

        if (parentClass name equals?("Class")) {
            current app(".instanceSize = ")
            realClass getNonMeta() writeSize(current, true) // instance = true

            current app(','). nl(). app(".size = ")
            realClass getNonMeta() writeSize(current, false) // instance = false
        } else {
            writeClassStructInitializers(this, parentClass getSuperRef() as ClassDecl, realClass, done, false)
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

                if (parentDecl isStatic()) {
                    continue // static funcs aren't written in classes
                }

                if (realDecl == null && parentDecl isAbstract()) {
                    writeDesignatedInit(this, parentDecl, realDecl, false)
                } else {
                    writeDesignatedInit(this, parentDecl, realDecl, true)
                }
            }
        }

        if (parentClass != realClass &&
            parentClass getNonMeta() != null &&
            parentClass getNonMeta() instanceOf?(InterfaceDecl) &&
            realClass getNonMeta() instanceOf?(InterfaceImpl)) {

            interfaceImpl := realClass getNonMeta() as InterfaceImpl
            for(alias: FunctionAlias in interfaceImpl getAliases()) {
                current nl(). app('.'). app(alias key getName()). app(" = (void*) ")
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

        current nl(). app('.')
        FunctionDeclWriter writeSuffixedName(this, parentDecl)
        current app(" = (void*) ")

        decl := realDecl ? realDecl : parentDecl
        FunctionDeclWriter writeFullName(this, decl)

        if(
            // final funcs are not in the vtable: no _impl.
            !decl isFinal &&
            // abstract funcs are in the vtable, but we don't have an _impl ourselves
            !decl isAbstract &&
            // externWithName(s) are just gateways to C functions: no _impl.
            !decl isExternWithName() &&
            // the caller of writeDesignatedInit has some logic on whether
            // or not to write the _impl suffix too.
            impl
        ) current app("_impl")

        current app(',')

    }

    writeStructTypedef: static func (this: Skeleton, cDecl: ClassDecl) {

        structName := cDecl underName()
        if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
        current nl(). app("struct _"). app(structName). app(";")
        current nl(). app("typedef struct _"). app(structName). app(" "). app(structName). app(";")
        if(cDecl getVersion()) VersionWriter writeEnd(this, cDecl getVersion())

    }

}
