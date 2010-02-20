import ClassDeclWriter, CoverDeclWriter, CGenerator, Skeleton
import ../../middle/[InterfaceDecl]

InterfaceDeclWriter: abstract class extends CGenerator {
    
    write: static func ~_interface (this: This, iDecl: InterfaceDecl) {
        
        ClassDeclWriter write(this, iDecl)
        CoverDeclWriter write(this, iDecl getFatType())
        
    }
    
}
