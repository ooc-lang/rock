
import HashMap, ArrayList, List

/**
 * A MultiMap allows a mapping from one key to several values
 */
MultiMap: class <K, V> extends HashMap<K, V> {

    init: func ~multiMap {
        init(10)
    }

    init: func ~multiMapWithCapa(.capacity) {
        if(!V inheritsFrom?(Object)) {
            Exception new(This, "Can't create multimaps of %s, V must inherit from Object." format(V name toCString())) throw()
        }
        super(capacity)
    }

    get: func ~_super (key: K) -> V {
        super(key) as Object
    }

    put: func ~_super (key: K, value: V) -> Bool {
        super(key, value)
    }

    remove: func ~_super (key: K) -> Bool {
        super(key)
    }

    put: func (key: K, value: V) -> Bool {
        already := getAll(key)
        if(already == null) {
            // First of the kind - just put it
            put~_super(key, value)
        } else if(already instanceOf?(List)) {
            // Already at least two - append to the list
            list := already as List<V>
            list add(value)
        } else {
            // Second of the kind - create a list
            list := ArrayList<V> new()
            list add(already)
            list add(value)
            put~_super(key, list)
        }
        return true
    }

    remove: func (key: K) -> Bool {
        already := getAll(key)
        match already {
            case null =>
                // Doesn't contain it
                false
            case list: List<V> =>
                // Already at least two - remove from the list, from last to first
                list removeAt(list lastIndex())
                if(list getSize() == 1) {
                    // Only one left - turn the list into a single element
                    put~_super(key, list first())
                }
                true
            case =>
                // Only one - remove it
                super(key)
        }
    }

    removeValue: func (key: K, value: V) -> Bool {
        already := getAll(key)
        match already {
            case null =>
                // Doesn't contain it
                false
            case list: List<V> =>
                // let list handle it
                res := list remove(value)
                if(res && list getSize() == 1) {
                    // Only one left - turn the list into a single element
                    put~_super(key, list first())
                }
                res
            case =>
                // Only one - remove it
                remove~_super(key)
        }
    }

    getAll: func (key: K) -> Object {
        get~_super(key) as Object
    }

    get: func (key: K) -> V {
        val := getAll(key)
        match val {
            case null =>
                null
            case list: List<V> =>
                list last()
            case =>
                val
        }
    }

    getEach: func (key: K, f: Func (V)) {
        val := getAll(key)
        match val {
            case null =>
                return
            case list: List<V> =>
                list each(f)
            case =>
                f(val)
        }
    }

    getEachUntil: func (key: K, f: Func (V) -> Bool) {
        val := getAll(key)
        match val {
            case null =>
                return
            case list: List<V> =>
                list eachUntil(f)
            case =>
                f(val)
        }
    }

    iterator: func -> MultiMapValueIterator<K, V> {
        MultiMapValueIterator<K, V> new(this)
    }

    backIterator: func -> MultiMapValueIterator<K, V> {
        /* TODO: stub */
        return null
    }

}

MultiMapValueIterator: class <K, V> extends BackIterator<V> {

    map: MultiMap<K, V>
    index := 0
    sub: Iterator<V>

    init: func ~multiMap (=map) {}

    hasNext?: func -> Bool { index < map getKeys() getSize() && (sub == null || sub hasNext?()) }

    next: func -> V {

        // not in list mode
        if(!sub) {
            // retrieve value
            key := map getKeys() get(index)
            val := map getAll(key) as Object
            if(val instanceOf?(List)) {
                // switch in list mode
                sub = val as List<V> iterator()
            } else {
                // no list - go to next element and return
                index += 1
                return val
            }
        }

        // in list mode
        if(sub) {
            val := sub next()
            if(!sub hasNext?()) {
                // end of the list? switch back in single mode
                index += 1
                sub = null
            }
            return val
        }

        return null
    }

    /* TODO: stub */

    hasPrev?: func -> Bool { false }

    prev: func -> V {
        null
    }

    remove: func -> Bool {
        return false
    }

}

operator [] <K, V> (map: MultiMap<K, V>, key: K) -> V {
    map get(key)
}

operator []= <K, V> (map: MultiMap<K, V>, key: K, value: V) {
    map put(key, value)
}
