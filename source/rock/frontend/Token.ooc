
import ../frontend/[BuildParams, CommandLine]
import text/Buffer
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
            "%s [%d, %d]" format(module getFullName(), getStart(), getEnd())
        ) : (
            "[%d, %d]" format(getStart(), getEnd())
        )
    }

    formatMessage: func ~noPrefix (message, type: String) -> String {
        formatMessage("", message, type)
    }

    formatMessage: func (prefix, message, type: String) -> String {
        if(module == null) {
            return "From unknown source [%s] %s" format(type, message)
        }

        b := Buffer new()

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

        // zap the end of the line that contains us
        while(true) {
            if(!fr hasNext?() || fr read() == '\n') break
            idx += 1
        }

        fr reset(lastNewLine == 0 ? 0 : lastNewLine + 1)
        over := Buffer new()

        if(type != "") {
            b append(prefix). append("%s:%d:%d %s %s" format(module getPath(".ooc"), lines, start - lastNewLine, type, message))
        } else if(message != "") {
            b append(prefix). append(message). append('\n')
        }

        b append(prefix)
        end := getEnd()
        for(i in (lastNewLine + 1)..(idx + 1)) {
            c := fr read()
            match (c) {
                case '\t' =>
                    b append("    ")
                    over append("    ")
                case '\n' =>
                    break // the outer loop, not the match.
                case =>
                    printf("%c", c)
                    if(i < start || i >= end) {
                        over append(' ')
                    } else {
                        over append('~')
                    }
            }
        }
        b append('\n'). append(prefix)
        b append(over toString())

        fr close()

        b toString()
    }

    getPath: func -> String {
        module getPathElement() + File separator + module getPath() + ".ooc"
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
