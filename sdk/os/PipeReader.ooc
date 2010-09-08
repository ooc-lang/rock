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
        if(buf == null || buf@ == '\0') eof = true

        return buf == null ? "" : buf as CString toString()
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
