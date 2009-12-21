import structs/[List, ArrayList, HashMap]
import ../middle/[Cast]
import Skeleton

CastWriter: abstract class extends Skeleton {

    write: static func ~cast (this: This, cast: Cast) {
        
        if(cast inner getType() isGeneric()) {
            
            current app("(* ("). app(cast type). app("*)"). app(cast inner). app(")")
            
        } else {
        
            current app('('). app(cast type). app(") "). app(cast inner)
            
        }
        
    }
    
}

