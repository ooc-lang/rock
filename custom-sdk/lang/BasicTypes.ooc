include stdlib, stdio, ctype, stdint, stdbool, string

/**
 * objects
 */
Object: abstract class {

    class: Class
        
    /// Instance initializer: set default values for a new instance of this class
    __defaults__: func {}
    
    /// Finalizer: cleans up any objects belonging to this instance
    __destroy__: func {}
    
    instanceOf: final func (T: Class) -> Bool {
        class inheritsFrom(T)
    }
    
}

Class: abstract class {
    
    /// Number of octets to allocate for a new instance of this class 
    instanceSize: SizeT
    
    /// Number of octets to allocate to hold an instance of this class
    /// it's different because for classes, instanceSize may greatly
    /// vary, but size will always be equal to the size of a Pointer.
    /// for basic types (e.g. Int, Char, Pointer), size == instanceSize
    size: SizeT

    /// Human readable representation of the name of this class
    name: String
    
    /// Pointer to instance of super-class
    super: const Class
    
    /// Create a new instance of the object of type defined by this class
    alloc: final func -> Object {
        printf("Allocating %d bytes!", instanceSize)
        object := gc_malloc(instanceSize) as Object
        if(object) {
            printf("Object allocated! setting class\n")
            object class = this
            printf("Running __defaults__()\n")
            object __defaults__()
        }
        printf("Returning object\n")
        return object
    }
    
    inheritsFrom: final func (T: Class) -> Bool {
        if(this == T) return true
        return (super ? super inheritsFrom(T) : false)
    }
    
}

None: class {init: func {}}


/**
 * Pointer type
 */
Void: cover from void
Pointer: cover from void*

/**
 * character and pointer types
 */
Char: cover from char
UChar: cover from unsigned char
WChar: cover from wchar_t

//String: cover from Char*
String: cover from char* {
    
    println: func {
        printf("%s\n", this)
    }
    
}

LLong: cover from long long
Int: cover from int extends LLong
UInt: cover from unsigned int extends LLong
Short: cover from short extends LLong
UShort: cover from unsigned short extends LLong
Long: cover from long extends LLong
ULong: cover from unsigned long extends LLong
ULLong: cover from unsigned long long extends LLong

/**
 * fixed-size integer types
 */
Int8: cover from int8_t
Int16: cover from int16_t
Int32: cover from int32_t
Int64: cover from int64_t

UInt8:  cover from uint8_t
UInt16: cover from uint16_t
UInt32: cover from uint32_t
UInt64: cover from uint64_t

//Octet: cover from UInt8
Octet: cover from uint8_t
SizeT: cover from size_t extends LLong
Bool: cover from bool

/**
 * real types
 */
Float: cover from float extends Double
LDouble: cover from long double
Double: cover from double
