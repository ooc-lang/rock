
import ../frontend/CommandLine
import text/Buffer
import io/[FileReader, File]
import ../middle/Module

/* Will go into the load method of Token */
nullToken : Token
nullToken = Token new(0, 0, null)

Token: cover {
    
    start, length : SizeT
    module: Module
    
    new: static func~fromData (data: Int*, module: Module) -> This {
        this : This
        this start =  data[0]
        this length = data[1]
        this module = module
        return this
    }
    
    new: static func (.start, .length, .module) -> This {
        this : This
        this start =  start
        this length = length
        this module = module
        return this
    }
    
    new: static func~copy (origin: This) -> This {
        // well that's quite stupid. but covers have value semantics
        // already, so no action is needed to make a "copy" of it.
        return origin
    }
    
    toString: func -> String { "[%d, %d]" format(getStart(), getEnd()) }
    
    throwWarning: func (message: String) {
        printMessage(message, "WARNING")
    }
    
    throwError: func (message: String) {
        printMessage(message, "ERROR")
        CommandLine failure()
    }
    
    printMessage: func (message, type: String) {
        if(module == null) {
            Exception new(This, "? [%s] %s" format(type, message)) throw()
        }
        
        fr := FileReader new(module getPathElement() + File separator + module getFullName() + ".ooc")
        
        lastNewLine := 0
        lines := 1
        idx := 0
        while(fr hasNext() && idx < start) {
            c := fr read()
            if(c == '\n') {
                lines += 1
                lastNewLine = idx
            }
            idx += 1
        }
        
        while(true) {
            if(!fr hasNext() || fr read() == '\n') break
            idx += 1
        }
        
        fr reset(lastNewLine == 0 ? 0 : lastNewLine + 1)
        over := Buffer new()
        
        "%s:%d:%d [%s] %s" format(module path + ".ooc", lines, start - lastNewLine, type, message) println()
        
        end := getEnd()
        for(i in (lastNewLine + 1)..idx) {
            c := fr read()
            if(c == '\t') {
                printf("    ")
                over append("    ")
            } else {
                printf("%c", c)
                if(i < start || i >= end) {
                    over append(' ')
                } else {
                    over append('^')
                }
            }
        }
        println()
        over toString() println()
    }
    
    getLength: func -> SizeT {
        return length
    }
    
    getStart: func -> SizeT {
        return start
    }
    
    getEnd: func -> SizeT {
        return start + length
    }

    equals: func (other: This) -> Bool {
        return memcmp(this&, other&, This size) == 0
    }
    
}
