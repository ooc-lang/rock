include stddef, stdlib, stdio, ctype, ./Array

version(!_MSC_VER) {
    // MSVC doesn't support C99, so no stdbool for it
    include stdbool
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


