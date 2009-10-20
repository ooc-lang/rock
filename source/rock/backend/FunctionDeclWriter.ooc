import ../middle/[FunctionDecl]
import Skeleton

FunctionDeclWriter: abstract class extends Skeleton {
    
    /** Write a function prototype */
    writePrototype: static func (this: This, fDecl: FunctionDecl) {
        current app(fDecl returnType). app(' '). app(fDecl name). app('(')
        // TODO write args =D
        current app(')')
    }
    
    write: static func ~function (this: This, fDecl: FunctionDecl) {
        // header
        current = hw
        current nl()
        writePrototype(this, fDecl)
        current app(';')
        
        // source
        current = cw
        current nl()
        writePrototype(this, fDecl)
        current app(" {"). tab()
        for(line in fDecl body) {
            current app(line)
        }
        current untab(). nl(). app("}")
    }
    
}

