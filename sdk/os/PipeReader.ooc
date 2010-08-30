import os/Pipe

PipeReader: class {

    eof := false
    pipe: Pipe
    buf: Char* = null

    BUF_SIZE := static 128

    init: func(=pipe) {}

    read: func() -> String {
        if(eof) return ""

        buf = pipe read(This BUF_SIZE)
        if(buf@ == '\0') eof = true

        return String new(buf as CString, strlen(buf))
    }

    hasNext?: func() -> Bool {
        !eof
    }

    toString: func -> String {
        sb := Buffer new()
        while(hasNext?()) {
            sb append(read() _buffer)
        }
        return sb toString()

    }
}
