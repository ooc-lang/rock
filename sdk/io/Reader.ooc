import text/Buffer

/**
 * The reader interface provides a medium-indendant way to read characters
 * from a source, e.g. a file, a string, an URL, etc.
 */
Reader: abstract class {
    marker: Long

    read: abstract func(chars: String, offset: Int, count: Int) -> SizeT
    read: abstract func ~char -> Char

    readUntil: func (end: Char) -> String {
        sb := Buffer new(40) // let's be optimistic
        while(hasNext()) {
            c := read()
            if(c == end) break
            sb append(c)
        }
        return sb toString()
    }

    readLine: func -> String {
        readUntil('\n') trimRight('\r')
    }

    peek: func -> Char {
        c := read()
        rewind(1)
        return c
    }

    skipWhile: func (unwanted: Char) {
        while(hasNext()) {
            c := read()
            if(c != unwanted) {
                rewind(1)
                break
            }
        }
    }

    hasNext: abstract func -> Bool
    rewind: abstract func(offset: Int)
    mark: abstract func -> Long
    reset: abstract func(marker: Long)
    skip: func(offset: Int) {
        if (offset < 0) {
            rewind(-offset)
        }
        else {
            for (i: Int in 0..offset) read()
        }
    }
}
