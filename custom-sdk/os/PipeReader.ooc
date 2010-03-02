import os/Pipe
import text/Buffer

PipeReader: class {

    pipe: Pipe
    buf: String = null
    init: func(=pipe) {}

    read: func() -> String {
        return buf
    }

    hasNext: func() -> Bool {
        buf = pipe read(1) as String
        buf  != "\0"
    }
    
    toString: func -> String {
        
        sb := Buffer new(128)
        while(hasNext()) {
            sb append(read())
        }
        return sb toString()
        
    }
}
