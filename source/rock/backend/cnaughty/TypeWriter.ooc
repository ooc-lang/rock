import structs/[List, ArrayList, HashMap]
import ../../middle/[Type]
import Skeleton

TypeWriter: abstract class extends Skeleton {

    write: static func ~_type (this: This, type: Type) {
        
        current app(type toString())
        
    }
    
    writeSpaced: static func (this: This, type: Type, doPrefix: Bool) {
        
        write(this, type)
        current app(' ')
        
    }
    
}

