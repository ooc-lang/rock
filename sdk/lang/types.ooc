include stddef, stdlib, stdio, ctype, stdint, stdbool, float, ./Array

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
    instanceOf: final func (T: Class) -> Bool {
        if(!this) return false
        class inheritsFrom(T)
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

    inheritsFrom: final func ~_class (T: Class) -> Bool {
        if(this == T) return true
        return (super ? super inheritsFrom(T) : false)
    }

}

Array: cover from _lang_array__Array {
    length: extern Int
    data: extern Pointer

    free: extern(_lang_array__Array_free) func
}

None: class {init: func {}}

/**
 * Pointer type
 */
Void: cover from void

Pointer: cover from Void* {
    toString: func -> String { "%p" format(this) }
}

/**
 * Comparable
 */
Comparable: interface {
    compareTo: func<T>(other: T) -> Int
}

LLong: cover from signed long long {

    toString:    func -> String { "%lld" format(this) }
    toHexString: func -> String { "%llx" format(this) }

    isOdd:  func -> Bool { this % 2 == 1 }
    isEven: func -> Bool { this % 2 == 0 }

    divisor?: func (divisor: Int) -> Bool {
        this % divisor == 0
    }

    in: func(range: Range) -> Bool {
        return this >= range min && this < range max
    }
}

Long:  cover from signed long  extends LLong
Int:   cover from signed int   extends LLong
Short: cover from signed short extends LLong

ULLong: cover from unsigned long long extends LLong {

    toString:    func -> String { "%llu" format(this) }

    in: func(range: Range) -> Bool {
        return this >= range min && this < range max
    }

}

ULong:  cover from unsigned long  extends ULLong
UInt:   cover from unsigned int   extends ULLong
UShort: cover from unsigned short extends ULLong

//INT_MIN,    INT_MAX  : extern const static Int
//UINT_MAX 			 : extern const static UInt
//LONG_MIN,  LONG_MAX  : extern const static Long
//ULONG_MAX			 : extern const static ULong
//LLONG_MIN, LLONG_MAX : extern const static LLong
//ULLONG_MAX			 : extern const static ULLong

INT_MAX := 2147483647
INT_MIN := -INT_MAX - 1

/**
 * fixed-size integer types
 */
Int8:  cover from int8_t  extends LLong
Int16: cover from int16_t extends LLong
Int32: cover from int32_t extends LLong
Int64: cover from int64_t extends LLong

UInt8:  cover from uint8_t  extends ULLong
UInt16: cover from uint16_t extends ULLong
UInt32: cover from uint32_t extends ULLong
UInt64: cover from uint64_t extends ULLong

//Octet: cover from UInt8
Octet:  cover from uint8_t
SizeT:  cover from size_t extends LLong
Bool:   cover from bool {
    toString: func -> String { this ? "true" : "false" }
}

/**
 * real types
 */
LDouble: cover from long double {

    toString: func -> String {
        str = gc_malloc(64) : String
        sprintf(str, "%.2Lf", this)
        str
    }

    abs: func -> This {
        return this < 0 ? -this : this
    }

}
Float: cover from float extends LDouble
Double: cover from double extends LDouble

DBL_MIN,  DBL_MAX : extern static const Double
FLT_MIN,  FLT_MAX : extern static const Float
LDBL_MIN, LDBL_MAX: extern static const LDouble

/**
 * custom types
 */
Range: cover {

    min, max: Int

    new: static func (.min, .max) -> This {
        this : This
        this min = min
        this max = max
        return this
    }

    reduce: func (f: Func (Int, Int) -> Int) -> Int {
        acc := f(min, min + 1)
        for(i in min + 2..max) acc = f(acc, i)
        acc
    }

}

/**
 * Closures
 */
Closure: cover {
    thunk  : Pointer
    context: Pointer
}

