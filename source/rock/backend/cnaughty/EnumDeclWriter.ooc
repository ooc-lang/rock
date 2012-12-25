
import ../../middle/EnumDecl
import Skeleton

EnumDeclWriter: abstract class extends Skeleton {

    writeTypedef: static func (this: Skeleton, eDecl: EnumDecl) {
        current = fw

        // extern EnumDecls shouldn't print a typedef.
        if(!eDecl isExtern()) {
            current nl(). app("typedef int "). app(eDecl underName()). app(';')
        }
    }

}
