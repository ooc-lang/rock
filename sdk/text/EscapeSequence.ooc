import math

EscapeSequence: class {
    valid := static 1
    needMore := static 2
    invalid := static 3

    /** is a function for decoding an escape sequence. It supports
      * the most common escape sequences and also hexadecimal (\x0a) and
      * octal (\101) escape sequences.
      * You have to pass the escape sequence *without* the leading backslash
      * as `sequence` and a pointer to the result char as `chr`.
      * The return value is one of `EscapeSequence valid` (`chr` contains a
      * valid value now), `EscapeSequence needMore` (`chr`'s content is
      * undefined, the escape sequence is incomplete (the case for "\x1") and
      * `EscapeSequence invalid` (like for "\u").
      */
    getCharacter: static func (sequence: String, chr: Char*) -> Int {
        match(sequence[0]) {
            case '\'' => chr@ = '\''
            case '"' => chr@ = '"'
            case '\\' => chr@ = '\\'
            case '0' => chr@ = '\0'
//            case 'a' => chr@ = '\a' /* TODO: ooc doesn't know it */
            case 'b' => chr@ = '\b'
            case 'f' => chr@ = '\f'
            case 'n' => chr@ = '\n'
            case 'r' => chr@ = '\r'
            case 't' => chr@ = '\t'
            case 'v' => chr@ = '\v'
            case 'x' => {
                /* \xhh */
                if(sequence length() >= 3) {
                    /* have enough. convert heaxdecimal to `chr`. TODO: not nice */
                    sequence = sequence toUpper()
                    chr@ = '\0'
                    for(i in 0..2) {
                        value := '\0'
                        if(sequence[2-i] >= 'A' && sequence[2-i] <= 'F') {
                            value = 10 as Char + sequence[2-i] - 'A'
                        } else if(sequence[2-i] >= '0' && sequence[2-i] <= '9') {
                            value = sequence[2-i] - '0'
                        } else {
                            /* invalid character in hexadecimal literal. */
                            return invalid
                        }
                        chr@ += ((pow(16, i) as Int) * value) as Char
                    }
                    return valid
                } else {
                    /* not enough characters. */
                    return needMore
                }
            }
            case => {
                /* octal? */
                if(sequence[0] >= '0' && sequence[0] < '8') {
                    /* octal. */
                    chr@ = '\0'
                    octLength := sequence length() - 1
                    for(i in 0..octLength + 1) {
                        value := '\0'
                        if(sequence[octLength-i] >= '0' && sequence[octLength-i] < '8') {
                            value = sequence[octLength-i] - '0'
                        } else {
                            /* invalid character in octal literal. */
                            return invalid
                        }
                        chr@ += ((pow(8, i) as Int) * value) as Char
                    }
                    return valid
                }
                /* wtf. */
                return invalid
            }
        }
        return valid
    }

    /** Unescape the string `s`. will handle hexadecimal, octal and one-character escape
     * escape sequences. Unknown escape sequences will just get the '\\' stripped. ("\\u" -> "u")
     */
    unescape: static func (s: String) -> String {
        buffer := Buffer new()
        i := 0
        while(i < s length()) {
            if(s[i] == '\\') {
                /* escape sequence starting! */
                i += 1
                j := i
                if(s[i] >= '0' && s[i] < '8') {
                    /* octal. */
                    while(j < s length() && s[j] >= '0' && s[j] < '8') {
                        j += 1
                    }
                } else if(s[i] == 'x') {
                    /* hexadecimal. */
                    j += 3
                } else {
                    /* one character */
                    j += 1
                }
                chr: Char
                if(getCharacter(s substring(i, j), chr&) == valid) {
                    /* valid escape sequence. */
                    buffer append(chr)
                } else {
                    /* invalid or incomplete escape sequence - just append the chars without the leading '\\'. */
                    buffer append(s substring(i, j))
                }
                i = j
            } else {
                /* ordinary character. */
                buffer append(s[i])
                i += 1
            }
        }
        return buffer toString()
    }

    /** Escape a string. will replace non-printable characters with equivalents like \something or \x??.
        You can chars that should not be escaped in `exclude`.
    **/
    escape: static func ~exclude (s: String, exclude: String) -> String {
        buf := Buffer new()
        for(chr in s) {
            if(!exclude contains?(chr) && (!chr printable?() || chr == '\'' || chr == '"' || chr == '\\')) {
                buf append(match chr {
                    case '\'' => "\\'"
                    case '"' => "\\\""
                    case '\\' => "\\\\"
                    case 0 => "\\0" /* won't happen */
        //            case 'a' => chr@ = '\a' /* TODO: ooc doesn't know it */
                    case '\b' => "\\b"
                    case '\f' => "\\f"
                    case '\n' => "\\n"
                    case '\r' => "\\r"
                    case '\t' => "\\t"
                    case '\v' => "\\v"
                    case => "\\x%02hhx" format(chr)
                })
            } else {
                buf append(chr)
            }
        }
        buf toString()
    }

    escape: static func ~excludeNothing (s: String) -> String {
        escape(s, "")
    }
}
