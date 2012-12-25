
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
     * 
     * @author Alexandros Naskos (Windows port)
     * @author Amos Wenger (Better cross-platform abstraction)
     */
    TerminalWin32: class extends TerminalHandler {
        bg := Color black
        fg := Color white

        /* Color codes */
        colors := [
            0 , // black
            7 , // grey
            9 , // blue
            12, // red
            14, // yellow
            31, // white
            10, // green
            13, // magenta
            11  // cyan
        ]

        _lookupColor: func (c: Color) -> Int {
            colors[c as Int]
        }

        setColor: func (=fg, =bg) {
            b := _lookupColor(bg)
            f := _lookupColor(fg)
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

        setAttr: func (attribute: Int) {
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

