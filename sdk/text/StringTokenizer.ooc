import structs/ArrayList

extend Buffer {

    split: func ~withChar(c: Char, maxTokens: SSizeT) -> ArrayList<This> {
        split(c&, 1, maxTokens)
    }

    /** split s and return *all* elements, including empties */
    split: func ~withStringWithoutmaxTokens(s: This) -> ArrayList<This> {
        split(s data, s size, -1)
    }

    split: func ~withCharWithoutmaxTokens(c: Char) -> ArrayList<This> {
        split(c&, 1, -1)
    }

    split: func ~withBufWithEmpties(s: This, empties: Bool) -> ArrayList<This> {
        split(s data, s size, empties ? -1 : 0)
    }

    split: func ~withCharWithEmpties(c: Char, empties: Bool) -> ArrayList<This> {
        split(c&, 1, empties ? -1 : 0)
    }

    /**
     * Split a buffer to form a list of tokens delimited by `delimiter`
     *
     * @param delimiter Buffer that separates tokens
     * @param maxTokens Maximum number of tokens
     *   - if positive, the last token will be the rest of the string, if any.
     *   - if negative, the string will be fully split into tokens
     *   - if zero, it will return all non-empty elements
     */
    split: func ~buf (delimiter: This, maxTokens: SSizeT) -> ArrayList<This> {
        split(delimiter data, delimiter size, maxTokens)
    }

    split: func ~pointer (delimiter: Char*, delimiterLength:SizeT, maxTokens: SSizeT) -> ArrayList<This> {
        findResults := findAll(delimiter, delimiterLength, true)
        maxItems := ((maxTokens <= 0) || (maxTokens > findResults size + 1)) ? findResults size + 1 : maxTokens
        result := ArrayList<This> new(maxItems)
        sstart: SizeT = 0 //source (this) start pos
        
        for (item in findResults) {
            if ((maxTokens > 0) && (result size == maxItems - 1)) break
            
            sdist := item - sstart // bytes to copy
            if (maxTokens != 0 || sdist > 0) {
                b := This new ((data + sstart) as CString, sdist)
                result add(b)
            }
            sstart += sdist + delimiterLength
        }

        if(result size < maxItems) {
            sdist := size - sstart // bytes to copy
            b := new((data + sstart) as CString, sdist)
            result add(b)
        }
        
        result
    }

}

extend String {

    split: func ~withChar (c: Char, maxTokens: SSizeT) -> ArrayList<This> {
        _bufArrayListToStrArrayList(_buffer split(c, maxTokens))
    }

    split: func ~withStringWithoutmaxTokens (s: This) -> ArrayList<This> {
        _bufArrayListToStrArrayList(_buffer split(s _buffer, -1))
    }

    split: func ~withCharWithoutmaxTokens(c: Char) -> ArrayList<This> {
        _bufArrayListToStrArrayList(_buffer split(c))
    }

    split: func ~withStringWithEmpties( s: This, empties: Bool) -> ArrayList<This> {
        _bufArrayListToStrArrayList(_buffer split(s _buffer, empties))
    }

    split: func ~withCharWithEmpties(c: Char, empties: Bool) -> ArrayList<This> {
        _bufArrayListToStrArrayList(_buffer split(c, empties))
    }

    /**
     * Split a string to form a list of tokens delimited by `delimiter`
     *
     * @param delimiter String that separates tokens
     * @param maxTokens Maximum number of tokens
     *   - if positive, the last token will be the rest of the string, if any.
     *   - if negative, the string will be fully split into tokens
     *   - if zero, it will return all non-empty elements
     */
    split: func ~str (delimiter: This, maxTokens: SSizeT) -> ArrayList<This> {
        _bufArrayListToStrArrayList(_buffer split(delimiter _buffer, maxTokens))
    }

}

StringTokenizer: class extends Iterable<String> {

    splitted: ArrayList<String>
    index := 0

    init: func ~withCharWithoutmaxTokens(input: String, delim: Char) {
        init~withChar(input, delim, -1)
    }

    init: func ~withStringWithoutmaxTokens(input: String, delim: String) {
        init~withString(input, delim, -1)
    }

    init: func ~withChar(input: String, delim: Char, maxTokens: SSizeT) {
        init~withString(input, delim toString(), maxTokens)
    }

    init: func ~withString(input, delim: String, maxTokens: SSizeT) {
        splitted = input split(delim, maxTokens)
    }

    iterator: func -> Iterator<String> { StringTokenizerIterator<String> new(this) }

    hasNext?: func -> Bool { index < splitted size }

    /**
     * @return the next token, or null if we're at the end.
     */
    nextToken: func() -> String {
        // at the end?
        if(!hasNext?()) return null
        index += 1
        splitted[index - 1]
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
