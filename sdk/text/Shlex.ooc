import text/[EscapeSequence]
import structs/ArrayList

ShlexState: enum {
    WAIT = 0
    WORD
    SQUOTED
    DQUOTED
}

/**
 * Shell-like string lexer.
 * 
 * Parses simple-quoted (') or double-quoted (") arguments,
 * and returns a list of token.
 */
Shlex: class {
    state: ShlexState
    buffer: Buffer
    result: ArrayList<String>
    backslash: Bool

    init: func {
        buffer = Buffer new()
        result = ArrayList<String> new()
    }

    _add: func (unquote: Bool) {
        if(unquote)
            result add(EscapeSequence unescape(buffer toString()))
        else
            result add(buffer toString())
        buffer = Buffer new()
    }

    close: func -> ArrayList<String> {
        if(buffer size) { /* TODO: non-public api? */
            result add(buffer toString())
        }
        result
    }

    feed: func ~char (chr: Char) {
        match state {
            case ShlexState WAIT => {
                /* ShlexState WAIT state: if `chr` is non-printable, just skip it. 
                   If `chr` is ', change to ShlexState SQUOTED. If `chr` is ", change to ShlexState DQUOTED.
                   If `chr` is printable, but neither " nor ', change to ShlexState WORD state and add it to the buffer. */
                if(chr whitespace?()) {
                    /* skip */
                } else if (chr == '"') {
                    state = ShlexState DQUOTED
                } else if (chr == '\'') {
                    state = ShlexState SQUOTED
                } else {
                    buffer append(chr)
                    state = ShlexState WORD
                }
            }
            case ShlexState WORD => {
                /* ShlexState WORD state: if `chr` is non-printable, add to result, change to ShlexState WAIT state.
                   Otherwise, add it to the buffer. */
                if(chr whitespace?()) {
                    _add(false)
                    state = ShlexState WAIT
                } else {
                    buffer append(chr)
                }
            }
            case => {
                /* ?QUOTED state:
                 *  - if a backslash is met, set `backslash` to true. If `backslash` already is true,
                 *    this means we've got a '\\\\'. In this case, set `backslash` back to false
                 *    and add '\\\\' to the buffer.
                 *  - if `backslash` is true, add a backslash and `chr` to the buffer. Set `backslash` to false.
                 *  - if `backslash` is false and the adequate quoting character, end the string,
                 *    set the state to ShlexState WAIT.
                 *  - if `backslash` is false and any other character, add it to the buffer.
                 */
                 if(chr == '\\') {
                    if(backslash) {
                        backslash = false
                        buffer append("\\\\")
                    } else {
                        backslash = true
                    }
                 } else if(backslash) {
                    buffer append('\\') .append(chr)
                    backslash = false
                 } else {
                    if(chr == match state { case ShlexState DQUOTED => '"'; case ShlexState SQUOTED => '\'' }) {
                        _add(true)
                        state = ShlexState WAIT
                    } else {
                        buffer append(chr)
                    }
                 }
            }
        }
    }

    feed: func ~string (s: String) {
        for(c in s) {
            feed(c)
        }
    }

    split: static func (s: String) -> ArrayList<String> {
        shlex := This new()
        shlex feed(s)
        shlex close()
    }
}
