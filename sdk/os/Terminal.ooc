import FileDescriptor

/**
 * Set text colors and attributes for VT100 compatible terminals
 * @author eagle2com
 * @autor shamanas (Windows port)
 */

Attr: class {
    /* text attribute codes */
    /* Reset All Attributes (return to normal mode) */
    reset =   0,
    /* Bright (Usually turns on BOLD) */
    bright =  1,
    /* Dim    */
    dim =     2,
    /* Underline */
    under =   4,
    /* Blink (Does this really work?????) */
    blink =   5,
    /* Reverse (swap background and foreground colors) */
    reverse = 7,
    /* Hidden */
    hidden =  8 : static const Int
}

// this should be a constant but gcc cant find the symbol o0
COLOR_FORMAT_STRING := "\033[%dm"

version (unix || apple) {

Color: class {
    /* Foreground color codes */
    black =      30,
    red =        31,
    green =      32,
    yellow =     33,
    blue  =      34,
    magenta =    35,
    cyan =       36,
    grey =       37,
    white  =     38    : static const Int
}

import unistd

Terminal: class {
    /* Background color codes are the same as Foreground + 10
     * example: background blue = 34 + 10 = 44
     */

    /** Output a terminal code to stdout **/
    output: static func(fmt : String, ...) {
        if (isatty(STDOUT_FILENO)) {
            va : VaList

            va_start(va, fmt)
            vprintf(fmt toCString(), va)
            va_end(va)
        }

        fflush(stdout)
    }

    /** Set foreground and background color */
    setColor: static func(f,b: Int) {
        setFgColor(f)
        setBgColor(b)
    }

    /** Set foreground color */
    setFgColor: static func(c: Int) {
        if(c >= 30 && c <= 37) {
            output(COLOR_FORMAT_STRING, c)
        }
    }

    /** Set background color */
    setBgColor: static func(c: Int) {
        if(c >= 30 && c <= 37) {
            output(COLOR_FORMAT_STRING, c + 10)
        }
    }

    /** Set text attribute */
    setAttr: static func(att: Int) {
        if(att >= 0 && att <= 8) {
            output(COLOR_FORMAT_STRING, att)
        }
    }

    /* Set reset attribute =) */
    /** Reset the terminal colors and attributes */
    reset: static func() {
        setAttr(Attr reset)
    }
}
}

version (windows) {
import native/win32/types
// TODO: Try to use GetConsoleScreenBufferInfo to keep bg/fg color when using SetFg/BgColor functions
GetStdHandle: extern func(mode: ULong) -> Handle
SetConsoleTextAttribute: extern func(console: Handle, attr: UShort) -> Bool

STD_OUTPUT_HANDLE: extern ULong

Color: class {
    /* Color codes */
    black = 0,
    grey = 7,
    blue = 9,
    red = 12,
    yellow = 14,
    white = 31,
    green  = 10,
    magenta = 13,
    cyan = 11 : static const Int
}

Terminal: class {
	bg,fg: static Int
	output: static func(fmt : String, ...) { // Kept only not to break programs
    }

    setColor: static func(f,b: Int) {
		fg = f
		bg = b
		wColor: UShort = ((b & 0x0F) << 4) + (f & 0x0F)
		hStdOut := GetStdHandle(STD_OUTPUT_HANDLE)
		SetConsoleTextAttribute(hStdOut, wColor)
    }

    setFgColor: static func(c: Int) {
		setColor(c,bg)
    }

    setBgColor: static func(c: Int) {
		setColor(fg,c)
    }

    setAttr: static func(att: Int) {
		if(att == Attr reset) {
			reset()
		}
    }

    reset: static func() {
		setColor(Color grey, Color black)
    }
}
}

version (!(unix || apple || windows)) {
Color: class {
    /* Foreground color codes */
    black =      30,
    red =        31,
    green =      32,
    yellow =     33,
    blue  =      34,
    magenta =    35,
    cyan =       36,
    grey =       37,
    white  =     38    : static const Int
}
Terminal: class {

    /* Background color codes are the same as Foreground + 10
     * example: background blue = 34 + 10 = 44
     */

    /** Output a terminal code to stdout **/
    output: static func(fmt : String, ...) {}

    /** Set foreground and background color */
    setColor: static func(f,b: Int) {}

    /** Set foreground color */
    setFgColor: static func(c: Int) {}

    /** Set background color */
    setBgColor: static func(c: Int) {}

    /** Set text attribute */
    setAttr: static func(att: Int) {}

    /* Set reset attribute =) */
    /** Reset the terminal colors and attributes */
    reset: static func() {}
}
}
