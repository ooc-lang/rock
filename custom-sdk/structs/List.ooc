import text/Buffer /* for List join */

/**
 * List interface for a data container
 */
List: abstract class <T> extends Iterable<T> {

    /**
     * Appends the specified element to the end of this list.
     */
    add: abstract func(element: T)
    
    /**
     * Inserts the specified element at the specified position in
     * this list. 
     */
    add: abstract func~withIndex(index: Int, element: T)
    
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
    addAll: func ~atStart (start: Int, list: Iterable<T>) {

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
        while(iter hasNext()) add(iter next())
        
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
        size := size()
        if(size > 0) {
            removeAt(size - 1)
            return true
        }
        return false
    }
    
    /**
     * @return true if this list contains the specified element.
     */
    contains: func(element: T) -> Bool {
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
    get: abstract func(index: Int) -> T
    
    /**
     * @return the index of the first occurence of the given argument,
     * (testing for equality using the equals method), or -1 if not found
     */
    indexOf: abstract func(element: T) -> Int
    
    /**
     * @return true if this list has no elements.
     */
    isEmpty: func() -> Bool {
        return (size() == 0);
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
    removeAt: abstract func(index: Int) -> T
    
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
    set: abstract func(index: Int, element: T) -> T
    
    /**
     * @return the number of elements in this list.
     */
    size: abstract func -> Int

    /**
     * @return an interator on this list
     */
    iterator: abstract func -> Iterator<T>
    
    /**
     * @return a copy of this list
     */
    clone: abstract func -> List<T>

    /**
     * @return the first element of this list
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
    lastIndex: func -> Int {
        return size() - 1
    }
    
    /**
     * Reverse this list (destructive)
     */
    reverse: func {
        i := 0
        j := size() - 1
        while (i <= j / 2) {
            set(i, set(j, get(i)))
            i += 1
            j -= 1
        }
    }
    
    /**
     * Convert this list to a raw C array
     */
    toArray: func -> Pointer {
        arr : T* = gc_malloc(size() * T size)
        for(i in 0..size()) {
            arr[i] = this[i]
        }
        return arr&
    }

    /*
    each: func (f: Func (T)) {
        for(i in 0..size()) {
            f(get(i))
        }
    }
    */

    join: func ~string (str: String) -> String {
        if(!this T inheritsFrom(String)) {
            Exception new("You cannot use `String join` with %s instances." format(this T name)) throw()
        }
        /* TODO: A more performant implementation is possible. */
        result := Buffer new()
        first := true
        for(item in this) {
            if(first)
                first = false
            else
                result append(str)
            result append(item as String)
        }
        result toString()
    }

    join: func ~char (chr: Char) -> String {
        join(String new(chr))
    }
}

/** Operators */
operator [] <T> (list: List<T>, i: Int) -> T { list get(i) }
operator []= <T> (list: List<T>, i: Int, element: T) { list set(i, element) }
operator += <T> (list: List<T>, element: T) { list add(element) }
operator -= <T> (list: List<T>, element: T) -> Bool { list remove(element) }
