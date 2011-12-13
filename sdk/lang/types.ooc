include stddef, stdlib, stdio, ctype, ./Array
import structs/HashMap, threading/Thread

version(!_MSC_VER) {
    // MSVC doesn't support C99, so no stdbool for it
    include stdbool
}

/**
 * Map of retained objects - objects with a retain count of 1 are not included
 * (this kind of solves the chicken-egg problem with creating a hashmap object
 * that starts with a retain count of 1)
 */
__g_retainMap: HashMap<Pointer, Int>

/**
 * A lock to delude ourselves into thinking that this is even remotely safe.
 * Probably be better to use something other than a mutex here.
 */
__g_retainLock: Mutex

version(!gc) {
    __g_retainMap = HashMap<Pointer, Int> new()
    __g_retainLock = Mutex new()
}

/**
 * objects
 */
Object: abstract class {

    class: Class

    /// Instance initializer: set default values for a new instance of this class
    __defaults__: func {}

    /// Finalizer: cleans up any objects belonging to this instance
    __destroy__: func {}

    /** return true if *class* is a subclass of *T*. */
    instanceOf?: final func (T: Class) -> Bool {
        if(!this) return false
        
        current := class
        while(current) {
            if(current == T) return true
            current = current super
        }
        false
    }

    /// Increments the retain count of the instance in a non-GC'ed environment.
    retain: final func -> This {
        version(!gc) {
            __g_retainMap put(this as Pointer, __g_retainMap get(this) + 1)
        }

        return this
    }

    /** Decrements the retain count of the instance in a non-GC'ed environment.
        If the retain count reaches zero, the instance is destroyed. */
    release: final func {
        version(!gc) {
            count := __g_retainMap get(this as Pointer)

            if (count == 0) {
                __destroy__()
                gc_free(this as Pointer)
            } else if (count == 1) {
                __g_retainMap remove(this as Pointer)
            } else {
                __g_retainMap put(this as Pointer, count - 1)
            }
        }
    }

}

Class: abstract class {

    /// Number of octets to allocate for a new instance of this class
    instanceSize: SizeT

    /** Number of octets to allocate to hold an instance of this class
        it's different because for classes, instanceSize may greatly
        vary, but size will always be equal to the size of a Pointer.
        for basic types (e.g. Int, Char, Pointer), size == instanceSize */
    size: SizeT

    /// Human readable representation of the name of this class
    name: String

    /// Pointer to instance of super-class
    super: const Class

    /// Create a new instance of the object of type defined by this class
    alloc: final func ~_class -> Object {
        object := gc_malloc(instanceSize) as Object
        if(object) {
            object class = this
        }
        return object
    }

    inheritsFrom?: final func ~_class (T: Class) -> Bool {
        current := this
        while(current) {
            if(current == T) return true
            current = current super
        }
        false
    }

}

Array: cover from _lang_array__Array {
    length: extern SizeT
    data: extern Pointer

    free: extern(_lang_array__Array_free) func
}

None: class {
    init: func { }
}

/**
 * Pointer type
 */
Void: cover from void

Pointer: cover from Void* {
    toString: func -> String { "%p" format(this) }
}

Bool: cover from bool {
    toString: func -> String { this ? "true" : "false" }
}

/**
 * Comparable
 */
Comparable: interface {
    compareTo: func<T>(other: T) -> Int
}

/**
 * Closures
 */
Closure: cover {
    thunk  : Pointer
    context: Pointer
}

/** An object storing a value and its class. */
Cell: class <T> {
    val: T

    init: func(=val) {}
}

operator [] <T> (c: Cell<T>, T: Class) -> T {
    if(!c T inheritsFrom?(T)) {
        Exception new(Cell, "Wants a %s, but got a %s" format(T name toCString(), c T name toCString()))
    }
    c val
}


