import structs/ArrayList

extend Buffer {
    split: func~withChar(c: Char, maxSplits: SSizeT) -> ArrayList <This> {
        split(c&, 1, maxSplits)
    }

    /** split s and return *all* elements, including empties */
    split: func~withStringWithoutMaxSplits(s: This) -> ArrayList <This> {
        split ( s data, s size, -1)
    }

    split: func~withCharWithoutMaxSplits(c: Char) -> ArrayList <This> {
        split(c&, 1, -1)
    }

    split: func~withBufWithEmpties( s: This, empties: Bool) -> ArrayList <This> {
        split (s data, s size, empties ? -1 : 0 )
    }

    split: func~withCharWithEmpties(c: Char, empties: Bool) -> ArrayList <This> {
        split( c& , 1,  empties ? -1 : 0 )
    }

    /** splits a string into an ArrayList, maxSplits denotes max elements of returned list
        if it is > 0, it will be splitted maxSplits -1 times, and in the last element the rest of the string will be held.
        if maxSplits is negative, it will return all elements, if 0 it will return all non-empty elements.
        pretty much the same as in java.*/
    // FIXME untested!
    split: func ~buf (delimiter: This, maxSplits: SSizeT) -> ArrayList <This> {
        split(delimiter data, delimiter size, maxSplits)
    }

    split: func ~pointer (delimiter: Char*, delimiterLength:SizeT, maxSplits: SSizeT) -> ArrayList <This> {
        //cprintf("self[%p:%s] split called with %p:%s", size, data, delimiterLength, delimiter)
        l := findAll(delimiter, delimiterLength, true)
        maxItems := ((maxSplits <= 0) || (maxSplits >= l size())) ? l size() : maxSplits
        result := ArrayList <This> new( maxItems )
        sstart: SizeT = 0 //source (this) start pos
        for (item in l) {
            if ( ( maxSplits > 0 ) && ( result size() == maxItems - 1 ) ) break
            sdist := item - sstart // bytes to copy
            if (maxSplits != 0 || sdist > 0) {
                b := This new ((data + sstart) as CString, sdist)
                result add ( b )
            }
            sstart += sdist + delimiterLength
        }
        sdist := size - sstart // bytes to copy
        b := This new ((data + sstart) as CString, sdist)
        result add ( b )
        //cprintf("split debug out:\n")
        //for (elem in result) cprintf("%p:%s\n", elem size, elem data)
        return result
    }
}


_bufArrayListToStrArrayList: func ( x : ArrayList<Buffer> ) -> ArrayList<String> {
    result := ArrayList<String> new( x size() )
    for (i in x) result add ( i toString() )
    result
}


extend String {


    split: func~withChar(c: Char, maxSplits: SSizeT) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withChar(c, maxSplits) )
    }

    split: func~withStringWithoutMaxSplits(s: This) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split ( s _buffer, -1) )
    }

    split: func~withCharWithoutMaxSplits(c: Char) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withCharWithoutMaxSplits(c) )
    }

    split: func~withStringWithEmpties( s: This, empties: Bool) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withBufWithEmpties (s _buffer, empties ) )
    }

    split: func~withCharWithEmpties(c: Char, empties: Bool) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withCharWithEmpties( c , empties ) )
    }

    split: func ~str (delimiter: This, maxSplits: SSizeT) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~buf ( delimiter _buffer, maxSplits ) )
    }
}

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
        splitted = input split(delim, maxSplits)
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
