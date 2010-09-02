import math/Random, structs/ArrayList /* for List shuffle */
import structs/HashMap /* for getStandardEquals() - should probably move that in a separate Module */

/**
 * List interface for a data container
 */
List: abstract class <T> extends BackIterable<T> {

	size: SSizeT {
		get {
			getSize()
		}
	}

    equals? := getStandardEquals(T)

    /**
     * Appends the specified element to the end of this list.
     */
    add: abstract func(element: T)

    /**
     * Inserts the specified element at the specified position in
     * this list.
     */
    add: abstract func~withIndex(index: SSizeT, element: T)

    /**
     * Appends all of the elements in the specified Collection to the
     * end of this list, in the order that they are returned by the
     * specified Collection's Iterator.
     */
    addAll: func (list: Iterable<T>) {

        addAll(0, list)

    }

    /**
     * Inserts all of the elements in the specified Collection into
     * this list, starting at the specified position.
     */
    addAll: func ~atStart (start: SSizeT, list: Iterable<T>) {

        if(start == 0) {
            for(element: T in list) {
                add(element)
            }
            return
        }

        index := 0
        iter := list iterator()
        while(index < start) {
            iter next()
            index += 1
        }
        while(iter hasNext?()) add(iter next())

    }

    /**
     * Removes all of the elements from this list.
     */
    clear: abstract func()

    /**
     * Removes the last element of the list, if any (=non-empty list).
     * @return true if it has removed an element, false if the list
     * was empty.
     */
    removeLast: func -> Bool {
        mysize := getSize()
        if(mysize > 0) {
            removeAt(mysize - 1)
            return true
        }
        return false
    }

    /**
     * @return true if this list contains the specified element.
     */
    contains?: func(element: T) -> Bool {
        return indexOf(element) != -1
    }

    /**
     * @return true if oldie has been replaced by kiddo
     */
    replace: func (oldie, kiddo: T) -> Bool {
        idx := indexOf(oldie)
        if(idx == -1) return false
        set(idx, kiddo)
        return true
    }

    /**
     * @return the element at the specified position in this list.
     */
    get: abstract func(index: SSizeT) -> T

    /**
     * @return the index of the first occurence of the given argument,
     * (testing for equality using the equals? method), or -1 if not found
     */
    indexOf: abstract func(element: T) -> Int

    /**
     * @return true if this list has no elements.
     */
    empty?: func() -> Bool {
        getSize() == 0
    }

    /**
     * @return the index of the last occurrence of the specified object
     * in this list.
     */
    lastIndexOf: abstract func(element: T) -> Int

    /**
     * Removes the element at the specified position in this list.
     * @return the element just removed
     */
    removeAt: abstract func(index: SSizeT) -> T

    /**
     * Removes a single instance of the specified element from this list,
     * if it is present (optional operation).
     * @return true if at least one occurence of the element has been
     * removed
     */
    remove: abstract func(element: T) -> Bool

    /**
     * Replaces the element at the specified position in this list with
     * the specified element.
     */
    set: abstract func(index: SSizeT, element: T) -> T

    /**
     * @return the number of elements in this list.
     */
    getSize: abstract func -> SizeT

    /**
       @return an interator on this list
     */
    iterator: abstract func -> BackIterator<T>

    /**
       @return a copy of this list
     */
    clone: abstract func -> List<T>

    /**
       @return a list of the same concrete type, empty.
       useful when writing algorithms that need to create
       new lists, but not of a specific type.
     */
    emptyClone: abstract func <K> (K: Class) -> List <K>

    emptyClone: func ~defaults -> List <T> { emptyClone(T) }

    /**
       Return two sublists. The first one contains all the elements
       for which f evaluated to true, the second one contains all the
       other elements.
     */
    split: func (f: Func(T) -> Bool, list1, list2: This<T>@) {
        list1 = emptyClone(); list2 = clone()
        for(x in this) {
            if(f(x)) {
                list2 remove(x); list1 add(x)
            }
        }
    }

    /**
       Return a list with all the elements in a random order
     */
    shuffle: func -> This<T> {
        shuffled := emptyClone()

        indexes := ArrayList<SSizeT> new()
        for(i in 0..getSize()) indexes add(i)

        while(!indexes empty?()) {
            i := Random randRange(0, indexes getSize())
            shuffled add(this[indexes removeAt(i) as SSizeT])
        }
        shuffled
    }

    /**
       @return the first element of this list
     */
    first: func -> T {
        return get(0)
    }

    /**
     * @return the last element of this list
     */
    last: func -> T {
        return get(lastIndex())
    }

    /**
     * @return the last index of this list (e.g. size() - 1)
     */
    lastIndex: func -> SSizeT {
        return getSize() - 1
    }

    /**
     * Reverse this list (destructive)
     */
    reverse!: func {
        i := 0
        j := size - 1
        limit := j / 2
        while (i <= limit) {
            set(i, set(j, get(i)))
            i += 1
            j -= 1
        }
    }

    /**
     * Reverse this list (non-destructive)
     */
    reverse: func -> This<T> {
        copy := clone()
        copy reverse!()
        copy
    }

    /**
     * Convert this list to a raw C array
     */
    toArray: func -> Pointer {
        arr : T* = gc_malloc(getSize() * T size)
        for(i in 0..getSize()) {
            arr[i] = this[i]
        }
        return arr& as Pointer
    }

    map: func <K> (f: Func (T) -> K) -> This<K> {
        copy := emptyClone(K)
        each(|x| copy add(f(x)))
        copy
    }


    filter: func (f: Func (T) -> Bool) -> This<T> {
        copy := emptyClone()
        each(|x| if(f(x)) copy add(x))
        copy
    }

    filterEach: inline func(f: Func(T) -> Bool, g: Func(T)) {
        filter(f) each(g)
    }

    itemsSizeInBytes: func -> SizeT {
        result := 0
        for(item in this) {
            if(T==String) result += item as String _buffer size
            else if (T==Buffer) result += item as Buffer size
            else if (T==Char) result += 1
            else result += T size
        }
        result
    }

    join: func ~stringDefault -> String { join("") }

    join: func ~string (str: String) -> String {
        result := Buffer new(itemsSizeInBytes())
        first := true
        for(item in this) {
            if(first)
                first = false
            else
                result append(str _buffer)

            match T {
                case String => result append((item as String) _buffer)
                case Buffer  => result append(item as Buffer)
                case Char   => result append(item as Char)
                case        => Exception new("You cannot use `List join` with %s instances." format(this T name toCString())) throw()
            }
        }
        result toString()
    }

    join: func ~char (chr: Char) -> String {
        join(chr toString())
    }
}

/* Operators */
operator [] <T> (list: List<T>, i: SSizeT) -> T { list get(i) }
operator []= <T> (list: List<T>, i: SSizeT, element: T) { list set(i, element) }
operator += <T> (list: List<T>, element: T) { list add(element) }
operator -= <T> (list: List<T>, element: T) -> Bool { list remove(element) }
