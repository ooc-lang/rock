import io/Writer

/**
   Wrapper upon io/Writer to allow easy writing of tabbed text.
 */
TabbedWriter: class {

    stream: Writer
    tabLevel := 0
    tabWidth := 4

    init: func (=stream) { }

    close: func {
        stream close()
    }

    app: func ~chr (c: Char) {
        stream write(c)
    }

    app: func ~str (s: String) {
        stream write(s)
    }

    printf: final func ~format (fmt: String, ...) {
        ap: VaList
        va_start(ap, fmt)
        vprintf(fmt, ap)
        va_end(ap)
    }

    printfln: final func ~format (fmt: String, ...) {
        ap: VaList
        va_start(ap, fmt)
        nl()
        vprintf(fmt, ap)
        va_end(ap)
    }

    writeTabs: func {
        stream write(" " times (tabLevel * tabWidth), tabLevel * tabWidth)
    }

    newUntabbedLine: func {
        stream write('\n')
    }

    nl: func {
        newUntabbedLine()
        writeTabs()
    }

    tab: func {
        tabLevel += 1
    }

    untab: func {
        tabLevel -= 1
    }

}
