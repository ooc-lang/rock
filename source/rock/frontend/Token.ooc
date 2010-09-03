import ../frontend/[BuildParams, CommandLine]
import io/[FileReader, File]
import ../middle/Module

/* Will go into the load method of Token */
nullToken : Token
nullToken = Token new(0, 0, null)

Token: cover {

    /** Start and length of a token, in bytes */
    start, length : SizeT

    /** Module this token comes from */
    module: Module

    init: func@ (=start, =length, =module) {}

    /**
     * Creates a new token enclosing this one and the one passed as an argument.
     *
     * Let's say you have:
     *    something doThing()
     *
     * Then something's token enclosing(doThing's token) will give you
     *    something doThing()
     *    ~~~~~~~~~~~~~~~~~~~
     *
     * And that's actually how it's used.
     *
     */
    enclosing: func (next: This) -> This {
        ex : This
        ex start = start
        ex length = (next start + next length) - start
        ex module = module
        ex
    }

    /**
     * Gives a string representation of the boundaries of this module
     */
    toString: func -> String {
        module != null ? (
            "%s [%d, %d]" format(module getFullName() toCString(), getStart(), getEnd())
        ) : (
            "[%d, %d]" format(getStart(), getEnd())
        )
    }

    formatMessage: func ~noPrefix (message, type: String) -> String {
        formatMessage("", message, type)
    }

    formatMessage: func (prefix, message, type: String) -> String {

        if(module == null) {
            return "From unknown source [%s] %s" format(type toCString(), message toCString())
        }

        b := Buffer new()
        b append("\n")

        fr := FileReader new(getPath())

        lastNewLine := 0
        lines := 1
        idx := 0
        // zap the lines before we start
        while(fr hasNext?() && idx < start) {
            c := fr read()
            if(c == '\n') {
                lines += 1
                lastNewLine = idx
            }
            idx += 1
        }
        //"lines = %d, lastNewLine = %d, idx = %d, start = %d" printfln(lines, lastNewLine, idx, start)

        // zap the end of the line that contains us
        if(fr hasNext?()) while(true) {
            // the order matters - we consider the end-of-file as a newline.
            if(fr read() == '\n' || !fr hasNext?()) break
            idx += 1
        }
        //"now idx = %d" printfln(idx)

        fr reset(lastNewLine == 0 ? 0 : lastNewLine + 1)
        over := Buffer new()

        if(type != "") {
            b append(prefix). append("%s:%d:%d %s %s\n" format(module getPath(".ooc") toCString(), lines, start - lastNewLine, type toCString(), message toCString()))
        } else if(message != "") {
            b append(prefix). append(message). append('\n')
        }

        b append(prefix)
        end := getEnd()
        beginning := true
        for(i in (lastNewLine + 1)..(idx + 1)) {
            c := fr read()
            if(beginning && c == '\n') continue
            beginning = false

            match (c) {
                case '\t' =>
                    b append("    ")
                    over append("    ")
                case '\n' =>
                    break // the outer loop, not the match.
                case =>
                    b append(c)
                    if(i < start || i >= end) {
                        over append(' ')
                    } else {
                        over append('~')
                    }
            }
        }
        b append('\n'). append(prefix)
        b append(over)

        fr close()
        b toString()
    }

    getPath: func -> String {
        module oocPath
    }

    getLineNumber: func -> Int {
        lines := 1
        idx := 0

        fr := FileReader new(getPath())

        // zap the lines before we start
        while(fr hasNext?() && idx < start) {
            c := fr read()
            if(c == '\n') {
                lines += 1
            }
            idx += 1
        }
        fr close()

        return lines
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

    equals?: func (other: This) -> Bool {
        return memcmp(this&, other&, This size) == 0
    }

}
