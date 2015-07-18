
version (windows) {

    import os/Terminal
    import native/win32/types

    GetStdHandle: extern func(mode: ULong) -> Handle
    SetConsoleTextAttribute: extern func(console: Handle, attr: UShort) -> Bool
    GetConsoleScreenBufferInfo: extern func(console: Handle, info: PConsoleScreenBufferInfo) -> Bool

    STD_OUTPUT_HANDLE: extern ULong

    /**
     * Implementation of TerminalHandler for Windows systems
     */
    TerminalWin32: class extends TerminalHandler {
        bg := (-1) as Color
        fg := (-1) as Color

        init: func

        /* Color codes */
        colors := static const [
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
            hStdOut := GetStdHandle(STD_OUTPUT_HANDLE)
            info: ConsoleScreenBufferInfo
            wColor: UShort = 0
            if(GetConsoleScreenBufferInfo(hStdOut, info&)){
                wColor = info attributes
            }
            b := _lookupColor(bg)
            f := _lookupColor(fg)
            if (b != -1) {
                wColor = wColor & 0xFF0F
            } else { b = 0 }
            if (f != -1) {
                wColor = wColor & 0xFFF0
            } else { f = 0 }

            wColor = wColor | (((b & 0x0F) << 4) + (f & 0x0F))
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

