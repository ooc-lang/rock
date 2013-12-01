
version (unix || apple) {

    import os/[Terminal, unistd, FileDescriptor]

    /**
     * Implementation of TerminalHandler for Unix systems (VT100 compatible terminals)
     *
     * Note: Background color codes are the same as Foreground + 10
     * example: background blue = 34 + 10 = 44
     */
    TerminalUnix: class extends TerminalHandler {

        init: func

        _lookupColor: func (c: Color) -> Int {
            // black = 30, and then the ordering is correct
            c as Int + 30
        }

        /** Output a terminal code to stdout **/
        _output: func (code: Int) {
            if (isatty(STDOUT_FILENO)) {
                "\033[%dm" format(code) print()
                fflush(stdout)
            }
        }

        /** Set foreground and background color */
        setColor: func (f, b: Color) {
            setFgColor(f)
            setBgColor(b)
        }

        /** Set foreground color */
        setFgColor: func (color: Color) {
            code := _lookupColor(color)
            _output(code)
        }

        /** Set background color */
        setBgColor: func (color: Color) {
            code := _lookupColor(color)
            _output(code + 10)
        }

        /** Set text attribute */
        setAttr: func (attribute: Attr) {
            code := attribute as Int
            _output(code)
        }

        /** Reset the terminal colors and attributes */
        reset: func {
            setAttr(Attr reset)
        }

    }

}

