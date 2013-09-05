
// sdk
import io/[StringReader]

/**
 * Demangles symbols on-demand.
 *
 * E.g. allows you to turn stuff like:
 *    `lang_Exception__Exception_throw_impl`
 * into:
 *    `Exception throw_impl() in lang/Exception`
 *
 * Used to display fancy backtraces, for example.
 */
Demangler: class {

    demangle: static func (s: String) -> FullSymbol {
        result := FullSymbol new(s)

        if (!s contains?("__")) {
            // simple symbol (non-ooc, unmangled function, etc.)
            return result
        }

        reader := StringReader new(s)

        while (reader hasNext?()) {
            c := reader read()
            match c {
                case '_' =>
                    if (reader peek() == '_') {
                        // it's the end! skip that second underscore
                        reader read()
                        break // while
                    } else {
                        // package element
                        result package += '/'
                    }
                case =>
                    // accumulate
                    result package += c
            }
        }

        if (reader peek() upper?()) {
            while (reader hasNext?()) {
                c := reader read()
                match c {
                    case '_' =>
                        // done!
                        break // while
                    case =>
                        // accumulate
                        result type += c 
                }
            }
        }

        result name = reader readAll()
        result
    }

}

/**
 * The result of demangling a symbol.
 * All members are safe to use but they may be empty.
 *
 * For display, use `fullName`, and package if it's
 * non-empty.
 */
FullSymbol: class {
    mangled: String

    init: func (=mangled) {
        name = mangled
    }

    package := ""
    type := ""
    name := ""

    fullName: String { get {
        match (type size) {
            case 0 =>
                name
            case =>
                "%s %s" format(type, name)
        }
    } }
}

