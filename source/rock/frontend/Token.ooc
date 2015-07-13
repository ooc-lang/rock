
// ours
import ../frontend/[BuildParams, CommandLine]
import ../middle/Module

// sdk
import io/[StringReader]
import os/Terminal

/* Token can't be null, but it can be filled with zero-values */
nullToken := (0, 0, null, 0) as Token

/**
 * A token stores the position in source of a particular piece of code,
 * like a symbol, an operator, any node really.
 *
 * It also contains method allowing pretty-printing of error messages,
 * with line & column numbers and even underlining.
 */
Token: cover {

    /** Start and length of this token, in bytes */
    start, length: Int

    /** Module this token comes from */
    module: Module

    /** 0-based line number of this token */
    lineno: Int

    /* No constructor, should be built with cover-literal syntax */

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

    /* MESSAGE PRINTING FUNCTIONS */

    /*
     * The following functions allow comfortable debugging of compiler
     * code by doing something like:
     *
     * MyNode: class extends Node {
     *    resolve: func (...) {
     *      if (debugCondition()) {
     *        token printMessage("Currently resolving #{this}!")
     *      }
     *    }
     * }
     */

    printMessage: func ~noType (message: String) {
        printMessage("", message, "info")
    }

    printMessage: func ~noPrefix (message, type: String) {
        printMessage("", message, type)
    }

    printMessage: func (prefix, message, type: String) {
        writeMessage(prefix, message, type, TerminalErrorOutput new())
    }

    formatMessage: func ~noPrefix (message, type: String) -> String {
        formatMessage("", message, type)
    }

    formatMessage: func (prefix, message, type: String) -> String {
        output := TextErrorOutput new()
        writeMessage(prefix, message, type, output)
        output toString()
    }

    /**
     * Writes a message like:
     *
     * test/compiler/generics.ooc:9:12 error No such function println() for `T`
     *   g list get(0) println()
     *          ~~~~~~~~~~~~~~
     *
     * Notably, it displays the path to to the ooc file, a line number and
     * a column, the line of code in question, and a wavy blue underline of
     * the part we're talking about.
     *
     * If you're seeing wrong highlights in the compiler output, it probably
     * means parsing went wrong (nagaqueen & rock having different interpretations
     * of whitespace?) or token propagation was done wrong in the AST (e.g.
     * lazily passing nullToken instead of relaying another node's token or even
     * using enclosing)
     */
    writeMessage: func (prefix, message, type: String, out: ErrorOutput) {
        if(module == null) {
            out append("From unknown source [%s] %s" format(type, message))
            return
        }

        out append("\n")

        fr := StringReader new(module getSource())

        lastNewLine := 0
        lines := 1
        idx := 0

        start := getStart()
        end := getEnd()

        // skip the lines before we start, remember index of the start of our line
        while(fr hasNext?() && idx < start) {
            c := fr read()
            match c {
                // CRLF (Win32)
                case '\r' =>
                    if (fr peek() == '\n') {
                        fr read()
                        idx += 1
                        lines += 1
                        lastNewLine = idx
                    }
                // LF (Linux, Mac)
                case '\n' =>
                  lines += 1
                  lastNewLine = idx
            }
            idx += 1
        }
        //"lines = %d, lastNewLine = %d, idx = %d, start = %d" printfln(lines, lastNewLine, idx, start)

        // skip the end of the line that contains us
        if(fr hasNext?()) while(true) {
            // the order matters - we consider the end-of-file as a newline.
            c := fr read()
            match c {
              case '\r' =>
                if (fr peek() == '\n') {
                  break
                }
              case '\n' =>
                break
            }
            if(!fr hasNext?()) break

            idx += 1
        }
        //"now idx = %d" printfln(idx)

        fr reset(lastNewLine == 0 ? 0 : lastNewLine + 1)
        over := Buffer new()

        if(type != "") {
            out append(prefix). append("%s:%d:%d " format(module getLocalPath(".ooc"), lines, start - lastNewLine))

            match type {
                case "error" =>
                    out setColor(Color red)
                case "warning" =>
                    out setColor(Color yellow)
                case "info" =>
                    out setColor(Color blue)
            }
            out append(type)
            out reset()
            out append(" "). append(message). append("\n")
        } else if(message != "") {
            out append(prefix). append(message). append('\n')
        }

        out append(prefix)
        beginning := true
        done := false

        out setColor(Color white)

        //"Iterating from %d to %d (start = %d, end = %d)" printfln(lastNewLine + 1, idx + 1, start, end)
        for(i in (lastNewLine + 1)..(idx + 1)) {
            c := fr read()
            if (beginning) {
              match c {
                // CRLF (Win32)
                case '\r' =>
                    if (fr peek() == '\n') {
                      fr read()
                      continue
                    }
                // LF (Linux, Mac)
                case '\n' =>
                    continue
              }
            }
            beginning = false

            match (c) {
                case '\t' =>
                    out append("    ")
                    over append("    ")
                // CRLF (Win32)
                case '\r' =>
                    if (fr peek() == '\n') {
                      fr read()
                      done = true
                    }
                // LF (Linux, Mac)
                case '\n' =>
                    done = true
                case =>
                    out append(c)
                    if(i < start || i >= end) {
                        over append(' ')
                    } else {
                        over append('~')
                    }
            }

            if (done) break
        }
        out append('\n'). append(prefix)

        out setColor(Color cyan)
        out append(over)

        fr close()
        out reset()
        out append("\n")
    }

    /**
     * Path to the ooc file this token has been parsed from
     */
    getPath: func -> String {
        module oocPath
    }

    /**
     * @return the 1-based line number of this token
     */
    getLineNumber: func -> Int {
        lineno + 1
    }

    /**
     * Length of this token in bytes
     */
    getLength: func -> Int {
        return (length > 0 ? length : -length)
    }

    /**
     * 0-based offset from the start of the file, in bytes
     */
    getStart: func -> Int {
        if (length > 0) {
            start
        } else {
            start + length
        }
    }

    /**
     * 0-based position of the end of this token, from the start of the file,
     * in bytes
     */
    getEnd: func -> Int {
        if (length > 0) {
            start + length
        } else {
            start
        }
    }

    equals?: func (other: This) -> Bool {
        return memcmp(this&, other&, This size) == 0
    }

}

/** 
 * Can receive error messages. Implementations may format to a string or
 * directly write on a terminal.
 */
ErrorOutput: abstract class {
    /* colors */
    setColor: abstract func (color: Color)
    reset: abstract func

    /*  output */
    append: abstract func ~char (c: Char)
    append: abstract func ~string (s: String)
    append: func ~buffer (buffer: Buffer) {
        append(buffer toString())
    }
}

/**
 * Outputs an error to a buffer, without color support (for example when rock's
 * output is being redirected, or when it's used on a platform that doesn't support
 * ANSI escapes)
 */
TextErrorOutput: class extends ErrorOutput {
    buffer := Buffer new()

    init: func
    
    setColor: func (color: Color) {
        /* text output is not colored - setColor is a no-op */
    }

    reset: func {
        /* nothing to reset, no-op as well */
    }

    append: func ~char (c: Char) {
        buffer append(c)
    }
    
    append: func ~string (s: String) {
        buffer append(s)
    }

    append: func ~buffer (b: Buffer) {
        buffer append(b)
    }
    
    toString: func -> String {
        buffer toString()
    }
}

/**
 * Outputs an error to a terminal, with color support. Relies on os/Terminal to
 * do so.
 */
TerminalErrorOutput: class extends ErrorOutput {

    init: func
    
    setColor: func (color: Color) {
        Terminal setFgColor(color)
    }

    reset: func {
        Terminal reset()
    }

    append: func ~char (c: Char) {
        c print()
    }
    
    append: func ~string (s: String) {
        s print()
    }
}

