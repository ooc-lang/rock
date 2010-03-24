import os/Pipe
import text/Buffer

PipeReader: class {

    eof := false
    pipe: Pipe
    buf: String = null
    
    BUF_SIZE := static 128
    
    init: func(=pipe) {}

    read: func() -> String {
        if(eof) return ""
        
        buf = pipe read(This BUF_SIZE)
        if(buf == "\0") eof = true
        
        return buf
    }

    hasNext: func() -> Bool {
        !eof
    }
    
    toString: func -> String {
        sb := Buffer new()
        while(hasNext()) {
            sb append(read())
        }
        return sb toString()
        
    }
}
