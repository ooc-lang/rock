
/**
 * iterators
 */
BufferIterator: class <T> extends BackIterator<T> {

    i := 0
    str: Buffer

    init: func ~withStr (=str) {}

    hasNext?: func -> Bool {
        i < str size
    }

    next: func -> T {
        c := (str data +i)@
        i += 1
        return c
    }

    hasPrev?: func -> Bool {
        i > 0
    }

    prev: func -> T {
        i -= 1
        return (str data + i)@
    }

    remove: func -> Bool { false } // this could be implemented!

}
