import structs/[List, ArrayList, HashMap]
import ../middle/[Type]
import Skeleton

TypeWriter: abstract class extends Skeleton {

    write: static func ~_type (this: This, type: Type) {
        
        // FIXME: stub
        current app(type toString())
        
    }
    
    writeSpaced: static func (this: This, type: Type, doPrefix: Bool) {
        
        // FIXME: stub
        write(this, type)
        current app(' ')
        
    }
    
}

