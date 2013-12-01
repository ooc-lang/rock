
version (windows) {

    import os/Terminal
    import native/win32/types

    // TODO: Try to use GetConsoleScreenBufferInfo to keep
    // bg/fg color when using SetFg/BgColor functions
    GetStdHandle: extern func(mode: ULong) -> Handle
    SetConsoleTextAttribute: extern func(console: Handle, attr: UShort) -> Bool

    STD_OUTPUT_HANDLE: extern ULong

    /**
     * Implementation of TerminalHandler for Windows systems
     */
    TerminalWin32: class extends TerminalHandler {
        bg := Color black
        fg := Color white

        init: func

        /* Color codes */
        colors := [
            0 , // black
            12, // red
            10, // green
            14, // yellow
            9 , // blue
            13, // magenta
            11, // cyan
            7 , // grey
            31  // white
        ]

        _lookupColor: func (c: Color) -> Int {
            value := c as Int
            if (value < 0 || value >= colors length) {
                -1
            } else {
                colors[value]
            }
        }

        setColor: func (=fg, =bg) {
            b := _lookupColor(bg)
            f := _lookupColor(fg)
            if (b == -1) {
                b = _lookupColor(Color black)
            }
            if (f == -1) {
                f = _lookupColor(Color grey)
            }

            wColor: UShort = ((b & 0x0F) << 4) + (f & 0x0F)
            hStdOut := GetStdHandle(STD_OUTPUT_HANDLE)
            SetConsoleTextAttribute(hStdOut, wColor)
        }

        setFgColor: func (c: Color) {
            setColor(c, bg)
        }

        setBgColor: func (c: Color) {
            setColor(fg, c)
        }

        setAttr: func (attribute: Attr) {
            // only the reset attribute is supported on Win32
            match attribute {
                case Attr reset =>
                    reset()
                // other cases are ignored
            }
        }

        reset: func {
            setColor(Color grey, Color black)
        }
    }

}

