import structs/[List, ArrayList] /* for Iterable<T> toArrayList */

/**
 * iterators
 */
Iterable: abstract class <T> {

    iterator: abstract func -> Iterator<T>

    /** Return the contents of the iterable as an ArrayList. */
    toList: func -> ArrayList<T> {
        result := ArrayList<T> new()
        for(elem: T in this) {
            result add(elem)
        }
        result
    }

    reduce: func (f: Func (T, T) -> T) -> T {
        iter := iterator()
        acc := f(iter next(), iter next())
        while(iter hasNext?()) acc = f(acc, iter next())
        acc
    }

    each: func (f: Func (T)) {
        for(elem in this) {
            f(elem)
        }
    }

    // Return false to break
    eachUntil: func (f: Func (T) -> Bool) {
        for(elem in this) {
            if(!f(elem)) break
        }
    }
    
    each: func ~withIndex (f: Func (T, Int)) {
        index := 0
        for(elem in this) {
            f(elem, index)
            index += 1
        }
    }

}

BackIterable: abstract class <T> extends Iterable<T> {

    iterator: abstract func -> BackIterator<T>

    /** Returns an iterator at the back or end of the Iterable. */
    backIterator: func -> BackIterator<T> {
        iter := iterator()
        while (iter hasNext?()) iter next()
        return iter
    }

    forward: func -> BackIterator<T> {iterator()}
    backward: func -> BackIterator<T> {backIterator() reversed()}
}

Iterator: abstract class <T> extends Iterable<T> {

    hasNext?: abstract func -> Bool
    next: abstract func -> T

    remove: abstract func -> Bool

    iterator: func -> Iterator<T> {this}

}

BackIterator: abstract class <T> extends Iterator<T> {
    hasPrev?: abstract func -> Bool
    prev: abstract func -> T

    iterator: func -> BackIterator<T> { this }

    reversed: func -> ReverseIterator<T> {
        iter := ReverseIterator<T> new()
        iter iterator = this
        return iter
    }
}

ReverseIterator: class <T> extends BackIterator<T> {
    init: func
    iterator: BackIterator<T> = null

    hasNext?: func -> Bool { iterator hasPrev?() }
    next: func -> T { iterator prev() }

    hasPrev?: func -> Bool { iterator hasNext?() }
    prev: func -> T { iterator next() }

    remove: func -> Bool { iterator remove() }

    reversed: func -> BackIterator<T> { iterator }

    iterator: func -> ReverseIterator<T> { this }

}
