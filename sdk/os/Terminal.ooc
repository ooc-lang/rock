
import os/native/[TerminalUnix, TerminalWin32]

/**
 * Set text colors and attributes for various terminals
 */
Terminal: class {

    handler: static TerminalHandler = null

    /** Set foreground and background color */
    setColor: static func(f, b: Color) {
        _getHandler() setColor(f, b)
    }

    /** Set foreground color */
    setFgColor: static func(c: Color) {
        _getHandler() setFgColor(c)
    }

    /** Set background color */
    setBgColor: static func(c: Color) {
        _getHandler() setBgColor(c)
    }

    /** Set text attribute */
    setAttr: static func(attribute: Attr) {
        _getHandler() setAttr(attribute)
    }

    /** Reset the terminal colors and attributes */
    reset: static func {
        _getHandler() reset()    
    }

    _getHandler: static func -> TerminalHandler {
        if (!handler) {
            handler = TerminalHandler new()
        }
        handler
    }

}

TerminalHandler: abstract class {

    new: static func -> This {
        version (windows) {
            return TerminalWin32 new()
        }
        version (unix || apple) {
            return TerminalUnix new()
        }
        // fall back to dummy terminal if unrecognized OS
        return TerminalDummy new()
    }

    /** Set foreground and background color */
    setColor: abstract func (f, b: Color)

    /** Set foreground color */
    setFgColor: abstract func (c: Color)

    /** Set background color */
    setBgColor: abstract func (c: Color)

    /** Set text attribute */
    setAttr: abstract func (attribute: Attr)

    /** Reset the terminal colors and attributes */
    reset: abstract func

}

TerminalDummy: class extends TerminalHandler {

    init: func

    /** Set foreground and background color */
    setColor: func (f, b: Color)

    /** Set foreground color */
    setFgColor: func (c: Color)

    /** Set background color */
    setBgColor: func (c: Color)

    /** Set text attribute */
    setAttr: func (attribute: Attr)

    /** Reset the terminal colors and attributes */
    reset: func

}

/**
 * Text attribute codes
 *
 * NB: most of those are unsupported on non-VT100 terminals
 * (e.g. on Windows)
 */
Attr: enum {
    /* Reset All Attributes (returns to normal mode) */
    reset = 0
    /* Bright (usually turns on BOLD) */
    bright = 1
    /* Dim    */
    dim = 2
    /* Underline */
    under = 4
    /* Blink (don't count on it) */
    blink = 5
    /* Reverse (swaps background and foreground colors) */
    reverse = 7
    /* Hidden */
    hidden = 8
}

/**
 * Color attribute codes
 */ 
Color: enum {
    black = 0
    red
    green
    yellow
    blue
    magenta
    cyan
    grey
    white

    fromHash: static func (hash: Int) -> This {
        min := red as Int
        max := cyan as Int
        value := (hash % (max - min)) + min
        value as This
    }
}

