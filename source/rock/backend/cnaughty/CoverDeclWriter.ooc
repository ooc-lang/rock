import structs/[List, ArrayList, HashMap]
import ../../middle/[ClassDecl, FunctionDecl, VariableDecl, TypeDecl, Type, Node, CoverDecl, FuncType]
import Skeleton, FunctionDeclWriter, TypeWriter, ClassDeclWriter, VersionWriter, ModuleWriter

CoverDeclWriter: abstract class extends Skeleton {

    write: static func ~_cover (this: Skeleton, cDecl: CoverDecl) {

        if (cDecl template) {
            if (cDecl instances) for (instance in cDecl instances) {
                // write templates instances
                This write(this, instance)

                meta := instance getMeta()
                // write templates instances' meta
                ClassDeclWriter write(this, meta)
            }

            // cover templates themselves are not written down, silly compilerbro
            return
        }

        current = hw

        // addons only add functions to an already imported cover, so
        // we don't need to struct it again, it would confuse the C compiler
        if(!cDecl isAddon() && !cDecl isExtern() && cDecl fromType == null) {
            writeGuts(this, cDecl)
        }

        for(fDecl in cDecl functions) {
            fDecl accept(this)
            current nl()
        }

        for(interfaceDecl in cDecl getInterfaceDecls()) {
            ClassDeclWriter write(this, interfaceDecl)
        }

    }

    writeGuts: static func (this: Skeleton, cDecl: CoverDecl) {

        if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())

        current nl(). app("struct _"). app(cDecl underName()). app(' '). openBlock()
        for(vDecl in cDecl variables) {
            current nl()
            if(vDecl isExtern() || vDecl isVirtual()) continue;
            vDecl type write(current, vDecl name)
            current app(';')
        }
        current closeBlock(). app(';'). nl()

        if(cDecl getVersion()) VersionWriter writeEnd(this, cDecl getVersion())

    }

    writeTypedef: static func (this: Skeleton, cDecl: CoverDecl) {

        if (cDecl template) {
            for (instance in cDecl instances) {
                // write-typedef template instances
                This writeTypedef(this, instance)

                meta := instance getMeta()
                // write-typedef template instances' meta
                ClassDeclWriter writeStructTypedef(this, meta)
            }

            // cover templates themselves are not written down, silly compilerbro
            return
        }

        if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())

        if(cDecl fromType && cDecl fromType getGroundType() instanceOf?(FuncType)) {
            // write func types covers as func types.
            ModuleWriter writeFuncType(this, cDecl fromType getGroundType() as FuncType, cDecl underName())
        } else if(!cDecl isAddon() && !cDecl isExtern()) {
            fromType := cDecl fromType
            if(!fromType) {
                current nl(). app("typedef struct _"). app(cDecl underName()).
                        app(' '). app(cDecl underName()). app(';')
            } else {
                current nl(). app("typedef ")
                current app(fromType getGroundType()). app(' '). app(cDecl underName()). app(';')
            }
        }

        if(cDecl getVersion()) VersionWriter writeEnd(this, cDecl getVersion())

    }

}

