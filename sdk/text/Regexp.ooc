use pcre

/**
    Low level PCRE cover used internally by Regexp
*/
Pcre: cover from pcre* {
    compile: extern(pcre_compile) static func(...) -> This
    free: extern(pcre_free) func
    exec: extern(pcre_exec) func(...) -> Int
    getStringNumber: extern(pcre_get_stringnumber) func(...) -> Int
}

RegexpOption: cover {
    ANCHORED: extern(PCRE_ANCHORED) static Int
    AUTO_CALLOUT: extern(PCRE_AUTO_CALLOUT) static Int
    CASELESS: extern(PCRE_CASELESS) static Int
    DOLLAR_ENDONLY: extern(PCRE_DOLLAR_ENDONLY) static Int
    DOTALL: extern(PCRE_DOTALL) static Int
    DUPNAMES: extern(PCRE_DUPNAMES) static Int
    EXTENDED: extern(PCRE_EXTENDED) static Int
    EXTRA: extern(PCRE_EXTRA) static Int
    FIRSTLINE: extern(PCRE_FIRSTLINE) static Int
    MULTILINE: extern(PCRE_MULTILINE) static Int
    NEWLINE_ANY: extern(PCRE_NEWLINE_ANY) static Int
    NEWLINE_CR: extern(PCRE_NEWLINE_CR) static Int
    NEWLINE_CRLF: extern(PCRE_NEWLINE_CRLF) static Int
    NEWLINE_LF: extern(PCRE_NEWLINE_LF) static Int
    NEWLINE_CAPTURE: extern(PCRE_NEWLINE_CAPTURE) static Int
    NO_AUTO_CAPTURE: extern(PCRE_NO_AUTO_CAPTURE) static Int
    UNGREEDY: extern(PCRE_UNGREEDY) static Int
    UTF8: extern(PCRE_UTF8) static Int
    NO_UTF8_CHECK: extern(PCRE_NO_UTF8_CHECK) static Int
}

/**
    Regular expression object
*/
Regexp: class {
    errorMsg: static String
    errorOffset: static Int

    pcre: Pcre
    maxSubstrings: Int = 30

    /**
        Compile a regular expression pattern.

        :param pattern: regular expression pattern to compile
        :param options: compiling options.
        :return: new regular expression object if successful, null if error occured.
    */
    compile: static func ~withOptions(pattern: String, options: Int) -> This {
        p := Pcre compile(pattern toCString(), options, (Regexp errorMsg&) as Pointer, Regexp errorOffset&, null)
        if(!p) {
            //TODO: once true exceptions work, throw an exception instead
            return null
        }
        return new(p)
    }
    compile: static func(pattern: String) -> This { compile(pattern, 0) }

    init: func(=pcre) {}

    __destroy__: func {
        pcre free()
    }

    /**
        If one or more characters from the start of the subject string
        matches the pattern, returns a Match object. Returns null if match fails.

        :param subject: subject string to test for match
        :param start: offset within subject at which to start matching
        :return: Match object if a match was found, otherwise null
    */
    matches: func ~withLengthAndStart(subject: String, start: Int, length: SizeT) -> Match {
        ovector: Int* = gc_malloc(Int size * maxSubstrings)
        count := pcre exec(null, subject toCString(), length, start, 0, ovector, maxSubstrings)
        if(count > 0) {
            return Match new(this, count, subject, ovector)
        }
        else return null
    }
    matches: func(subject: String) -> Match { matches(subject, 0, subject length()) }
}

/**
    Regular expression match object.
*/
Match: class extends Iterable<String> {
    regexp: Regexp
    groupCount: Int
    subject: String
    ovector: Int*

    init: func ~_match (=regexp, =groupCount, =subject, =ovector) {}

    /**
        Returns the starting position of the match group by index.
    */
    start: func ~byIndex(index: Int) -> Int {
        (ovector + (index * 2))@
    }

    /**
        Returns the ending position of the match group by index.
    */
    end: func ~byIndex(index: Int) -> Int {
        (ovector + (index * 2) + 1)@
    }

    groupStart: func ~byIndex(index: Int) -> Int {
        if(index >= groupCount) {
            Exception new("Invalid group index: %d" format(index)) throw()
        }

        offset := index * 2
        return ovector[offset]
    }

    groupLength: func ~byIndex(index: Int) -> Int {
        if(index >= groupCount) {
            Exception new("Invalid group index: %d" format(index)) throw()
        }

        offset := index * 2
        return ovector[offset + 1] - ovector[offset]
    }


    /**
        Returns a subgroup of the matched string by index.
    */
    group: func ~byIndex(index: Int) -> String {
        if(index >= groupCount) {
            Exception new("Invalid group index: %d" format(index)) throw()
        }

        offset := index * 2
        return subject substring(ovector[offset], ovector[offset + 1])
    }

    /**
        Returns a subgroup of the matched string by name.
    */
    group: func ~byName(name: String) -> String {
        number := regexp pcre getStringNumber(name toCString())
        if(number < -1) Exception new("Invalid group name: %s" format(name toCString())) throw()
        return group(number)
    }

    iterator: func -> Iterator<String> { MatchGroupIterator<String> new(this) }
}

MatchGroupIterator: class <T> extends Iterator<T> {
    matchObject: Match
    index: Int

    init: func ~matchGroupIter (=matchObject) {
        T = String
        index = 0
    }

    hasNext?: func -> Bool { index < matchObject groupCount }
    next: func -> T {
        s := matchObject group(index)
        index += 1
        return s
    }

    hasPrev?: func -> Bool { index > 0 }
    prev: func -> T {
        index -= 1
        return matchObject group(index)
    }

    remove: func -> Bool { false }
}
