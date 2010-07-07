
import ../frontend/[BuildParams, CommandLine]
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
        this
    }

    new: static func (.start, .length, .module) -> This {
        this : This
        this start =  start
        this length = length
        this module = module
        this
    }

    new: static func~copy (origin: This) -> This {
        // well that's quite stupid. but covers have value semantics
        // already, so no action is needed to make a "copy" of it.
        return origin
    }

    enclosing: func (next: This) -> This {
        ex : This
        ex start = start
        ex length = (next start + next length) - start
        ex module = module
        ex
    }

    toString: func -> String {
        module != null ? (
            "%s [%d, %d]" format(module getFullName(), getStart(), getEnd())
        ) : (
            "[%d, %d]" format(getStart(), getEnd())
        )
    }

    throwWarning: func (message: String) {
        printMessage(message, "[WARNING]")
    }

    throwError: func (message: String) {
        printMessage(message, "[ERROR]")
        if(BuildParams fatalError) CommandLine failure()
    }

    printMessage: func ~noPrefix (message, type: String) {
        printMessage("", message, type)
    }

    printMessage: func (prefix, message, type: String) {
        if(module == null) {
            Exception new(This, "From unknown source [%s] %s" format(type, message)) throw()
        }

        fr := FileReader new(getPath())

        lastNewLine := 0
        lines := 1
        idx := 0
        // zap the lines before we start
        while(fr hasNext() && idx < start) {
            c := fr read()
            if(c == '\n') {
                lines += 1
                lastNewLine = idx
            }
            idx += 1
        }

        // zap the end of the line that contains us
        while(true) {
            if(!fr hasNext() || fr read() == '\n') break
            idx += 1
        }

        fr reset(lastNewLine == 0 ? 0 : lastNewLine + 1)
        over := Buffer new()

        if(type != "") {
            prefix print()
            "%s:%d:%d %s %s" format(module getPath(".ooc"), lines, start - lastNewLine, type, message) println()
        } else if(message != "") {
            prefix print()
            message println()
        }

        prefix print()
        end := getEnd()
        for(i in (lastNewLine + 1)..(idx + 1)) {
            c := fr read()
            match (c) {
                case '\t' =>
                    printf("    ")
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
        println()
        prefix print()
        over toString() println()

        fr close()
    }

    getPath: func -> String {
        module getPathElement() + File separator + module getPath() + ".ooc"
    }

    getLineNumber: func -> Int {
        lines := 1
        idx := 0

        fr := FileReader new(getPath())

        // zap the lines before we start
        while(fr hasNext() && idx < start) {
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

    equals: func (other: This) -> Bool {
        return memcmp(this&, other&, This size) == 0
    }

}
