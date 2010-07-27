import ClassDeclWriter, CoverDeclWriter, CGenerator, Skeleton
import ../../middle/[InterfaceDecl]

InterfaceDeclWriter: abstract class extends Skeleton {

    write: static func ~_interface (this: Skeleton, iDecl: InterfaceDecl) {

        ClassDeclWriter write(this, iDecl)
        CoverDeclWriter write(this, iDecl getFatType())

    }

}
