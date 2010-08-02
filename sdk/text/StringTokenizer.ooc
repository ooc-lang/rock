import structs/ArrayList

StringTokenizer: class extends Iterable<String> {

    splitted : ArrayList<String>
    index = 0 : Int

    init: func~withCharWithoutMaxSplits(input: String, delim: Char) {
        init~withChar(input, delim, -1)
    }

    init: func~withStringWithoutMaxSplits(input: String, delim: String) {
        init~withString(input, delim, -1)
    }

    init: func~withChar(input: String, delim: Char, maxSplits: SSizeT) {
        init~withString(input, String new(delim), maxSplits)
    }

    init: func~withString(input, delim: String, maxSplits: SSizeT) {
        T = String // small fix for runtime introspection
        if (input != null) {
            length = input length()
            splitted = input splitMulti(delim, maxSplits)
        }
        splits = 0
    }

    iterator: func -> Iterator<String> { StringTokenizerIterator<String> new(this) }

    hasNext?: func -> Bool { splitted != null && index < splitted size }

    /**
     * @return the next token, or null if we're at the end.
     */
    nextToken: func() -> String {
        // at the end?
        if(!hasNext?() || splitted == null ) return null
        index += 1
        return splitted get(index -1)
    }
}

StringTokenizerIterator: class <T> extends Iterator<T> {

    st: StringTokenizer
    index := 0

    init: func ~sti (=st) {}
    hasNext?: func -> Bool { st hasNext?() }
    next: func -> T       { st nextToken() }
    hasPrev?: func -> Bool { false }
    prev: func -> T       { null }
    remove: func -> Bool  { false }

}