import structs/[List, ArrayList] /* for Iterable<T> toArrayList */
import text/Buffer /* for String replace ~string */

include stddef, stdlib, stdio, ctype, stdint, stdbool
include float

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

    /*
    toString: func -> String {
        "%s@%p" format(class name, this)
    }
    */
    
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
        object := gc_malloc(instanceSize) as Object
        if(object) {
            object class = this
        }
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
Pointer: cover from void* {
    toString: func -> String { "%p" format(this) }
}

/**
 * character and pointer types
 */
Char: cover from char {
    
    /** check for an alphanumeric character */
    isAlphaNumeric: func -> Bool {
        isAlpha() || isDigit()
    }

    /** check for an alphabetic character */
    isAlpha: func -> Bool {
        isLower() || isUpper()
    }

    /** check for a lowercase alphabetic character */
    isLower: func -> Bool {
        this >= 'a' && this <= 'z'
    }

    /** check for an uppercase alphabetic character */
    isUpper: func -> Bool {
        this >= 'A' && this <= 'Z'
    }

    /** check for a decimal digit (0 through 9) */
    isDigit: func -> Bool {
        this >= '0' && this <= '9'
    }

    /** check for a hexadecimal digit (0 1 2 3 4 5 6 7 8 9 a b c d e f A B C D E F) */
    isHexDigit: func -> Bool {
        isDigit() ||
        (this >= 'A' && this <= 'F') ||
        (this >= 'a' && this <= 'f')
    }

    /** check for a control character */
    isControl: func -> Bool {
        (this >= 0 && this <= 31) || this == 127
    }

    /** check for any printable character except space */
    isGraph: func -> Bool {
        isPrintable() && this != ' '
    }

    /** check for any printable character including space */
    isPrintable: func -> Bool {
        this >= 32 && this <= 126
    }

    /** check for any printable character which is not a space or an alphanumeric character */
    isPunctuation: func -> Bool {
        isPrintable() && !isAlphaNumeric() && this != ' '
    }

    /** check for white-space characters: space, form-feed ('\\f'), newline ('\\n'),
        carriage return ('\\r'), horizontal tab ('\\t'), and vertical tab ('\\v') */
    isWhitespace: func -> Bool {
        this == ' '  ||
        this == '\f' ||
        this == '\n' ||
        this == '\r' ||
        this == '\t' ||
        this == '\v'
    }

    /** check for a blank character; that is, a space or a tab */
    isBlank: func -> Bool {
        this == ' ' || this == '\t'
    }

    /** convert to an integer. This only works for digits, otherwise -1 is returned */
    toInt: func -> Int {
        if (isDigit()) {
            return (this - '0')
        }
        return -1
    }

    /** return the lowered character */
    toLower: extern(tolower) func -> This

    /** return the capitalized character */
    toUpper: extern(toupper) func -> This

    /** return a one-character string containing this character. */
    toString: func -> String {
        String new(this)
    }

    /** write this character to stdout without a following newline. */
    print: func {
        printf("%c", this)
    }

    /** write this character to stdout, followed by a newline */
    println: func {
        printf("%c\n", this)
    }
    
}

SChar: cover from signed char extends Char
UChar: cover from unsigned char extends Char
WChar: cover from wchar_t

operator as (value: Char) -> String {
    value toString()
}

strtol:  extern func (Char*, Pointer, Int) -> Long
strtoll: extern func (Char*, Pointer, Int) -> LLong
strtoul: extern func (Char*, Pointer, Int) -> ULong
strtof:  extern func (Char*, Pointer)      -> Float
strtod:  extern func (Char*, Pointer)      -> Double
strtold: extern func (Char*, Pointer)      -> LDouble

strlen:  extern func (Char*) -> Int

String: cover from Char* {

    /** Create a new string exactly *length* characters long (without the nullbyte).
        The contents of the string are undefined. */
    new: static func~withLength (length: Int) -> This {
        result := gc_malloc(length + 1) as This
        result[length] = '\0'
        result
    }

    /** Create a new string of the length 1 containing only the character *c* */
    new: static func~withChar (c: Char) -> This {
        result := This new~withLength(1)
        result[0] = c
        result
    }

    /** compare *length* characters of *this* with *other*, starting at *start*.
        Return true if the two strings are equal, return false if they are not. */
    compare: func (other: This, start, length: Int) -> Bool {
        for(i: Int in 0..length) {
            if(this[start + i] != other[i]) {
                return false
            }
        }
        return true
    }

    /** compare *this* with *other*, starting at *start*. The count of compared
        characters is determined by *other*'s length. */
    compare: func ~implicitLength (other: This, start: Int) -> Bool {
        compare(other, start, other length())
    }

    /** compare *this* with *other*, starting at 0. Compare ``other length()`` characters. */
    compare: func ~whole (other: This) -> Bool {
        compare(other, 0, other length())
    }

    /** return the string's length, excluding the null byte. */
    length: extern(strlen) func -> Int

    /** return true if *other* and *this* are equal. This also returns false if either
        of these two is ``null``. */
    equals: func(other: String) -> Bool {
        if ((this == null) || (other == null)) {
            return false
        }
        if (this length() != other length()) {
            return false
        }
        for (i : Int in 0..other length()) {
            if (this[i] != other[i]) {
                return false
            }
        }
        return true
    }

    /** TODO: make these inline again once inlines are fixed **/

    /** convert the string's contents to Int. */
    toInt: func -> Int                       { strtol(this, null, 10)   }
    toInt: func ~withBase (base: Int) -> Int { strtol(this, null, base) }

    /** convert the string's contents to Long. */
    toLong: func -> Long                        { strtol(this, null, 10)   }
    toLong: func ~withBase (base: Long) -> Long { strtol(this, null, base) }

    /** convert the string's contents to Long Long. */
    toLLong: func -> LLong                         { strtol(this, null, 10)   }
    toLLong: func ~withBase (base: LLong) -> LLong { strtol(this, null, base) }

    /** convert the string's contents to Unsigned Long. */
    toULong: func -> ULong                         { strtoul(this, null, 10)   }
    toULong: func ~withBase (base: ULong) -> ULong { strtoul(this, null, base) }

    /** convert the string's contents to Float. */
    toFloat: func -> Float                         { strtof(this, null)   }

    /** convert the string's contents to Double. */
    toDouble: func -> Double                       { strtod(this, null)   }

    /** convert the string's contents to Long Double. */
    toLDouble: func -> LDouble                     { strtold(this, null)   }

    /** return true if the string is empty or ``null``. */
    isEmpty: func -> Bool { (this == null) || (this[0] == 0) }

    /** return true if the first characters of *this* are equal to *s*. */
    startsWith: func(s: This) -> Bool {
        if (this length() < s length()) return false
        for (i: Int in 0..s length()) {
            if(this[i] != s[i]) return false
        }
        return true
    }

    /** return true if the first character of *this* is equal to *c*. */
    startsWith: func~withChar(c: Char) -> Bool {
        return this[0] == c
    }

    /** return true if the last characters of *this* are equal to *s*. */
    endsWith: func(s: String) -> Bool {
        l1 = this length() : Int
        l2 = s length() : Int
        if(l1 < l2) return false
        offset = (l1 - l2) : Int
        for (i: Int in 0..l2) {
            if(this[i + offset] != s[i]) {
                return false
            }
        }
        return true
    }

    /** return the index of *c*, starting at 0. If *this* does not contain
        *c*, return -1. */
    indexOf: func ~charZero (c: Char) -> Int {
        indexOf(c, 0)
    }

    /** return the index of *c*, but only check characters ``start..length``.
        However, the return value is the index of the *c* relative to the
        string's beginning. If *this* does not contain *c*, return -1. */
    indexOf: func ~char (c: Char, start: Int) -> Int {
        length := length()
        for(i: Int in start..length) {
            if(this[i] == c) {
                return i
            }
        }
        return -1
    }

    /** return the index of *s*, starting at 0. If *this* does not contain *s*,
        return -1. */
    indexOf: func ~stringZero (s: This) -> Int {
        indexOf~string(s, 0)
    }

    /** return the index of *s*, but only check characters ``start..length``.
        However, the return value is relative to the *this*' first character.
        If *this* does not contain *c*, return -1. */
    indexOf: func ~string (s: This, start: Int) -> Int {
        length := length()
        slength := s length()
        for(i: Int in start..length) {
            if(compare(s, i, slength))
                return i
        }
        return -1
    }

    /** return *true* if *this* contains the character *c* */
    contains: func ~char (c: Char) -> Bool { indexOf(c) != -1 }

    /** return *true* if *this* contains the string *s* */
    contains: func ~string (s: This) -> Bool { indexOf(s) != -1 }

    /** return a copy of *this* with space characters (ASCII 32) stripped at both ends. */
    trim: func ~space -> This { return trim(' ') }

    /** return a copy of *this* with *c* characters stripped at both ends. */
    trim: func(c: Char) -> This {
        if(length() == 0) return this

        start := 0
        while(this[start] == c) start += 1;

        end := length()
        if(start >= end) return ""
        while(this[end - 1] == c) end -= 1;

        if(start != 0 || end != length()) return substring(start, end)

        return this
    }

    /** return a copy of *this* with all characters contained by *s* stripped
        at both ends. */
    trim: func ~string (s: This) -> This {
        if(length() == 0) return this

        start := 0
        while(s contains(this[start])) start += 1;

        end := length()
        if(start >= end) return ""
        while(s contains(this[end - 1])) end -= 1;

        if(start != 0 || end != length()) return substring(start, end)

        return this
    }

    /** return a copy of *this* with space characters (ASCII 32) stripped from the left side. */
    trimLeft: func ~space -> This { return trimLeft(' ') }

    /** return a copy of *this* with *c* characters stripped from the left side. */
    trimLeft: func (c: Char) -> This {
        if(length() == 0) return this

        start := 0
        while(this[start] == c) start += 1;

        end := length()
        if(start >= end) return ""

        if(start != 0) return substring(start)

        return this
    }

    /** return a copy of *this* with all characters contained by *s* stripped
        from the left side. */
    trimLeft: func ~string (s: String) -> This {
        if(length() == 0) return this

        start := 0
        while(s contains(this[start])) start += 1;

        end := length()
        if(start >= end) return ""

        if(start != 0) return substring(start)

        return this
    }

    /** return a copy of *this* with space characters (ASCII 32) stripped from the right side. */
    trimRight: func ~space -> This { return trimRight(' ') }

    /** return a copy of *this* with *c* characters stripped from the right side. */
    trimRight: func (c: Char) -> This {
        if(length() == 0) return this

        end := length()
        if(0 >= end) return ""
        while(this[end - 1] == c) end -= 1;

        if(end != length()) return substring(0, end)

        return this
    }

    /** return a copy of *this* with all characters contained by *s* stripped
        from the right side. */
    trimRight: func ~string (s: String) -> This {
        if(length() == 0) return this

        end := length()
        while(s contains(this[end - 1])) end -= 1;
        if(0 >= end) return ""

        if(end != length()) return substring(0, end)

        return this
    }

    /** return the first character of *this*. If *this* is empty, 0 is returned. */
    first: func -> Char {
        return this[0]
    }

    /** return the index of the last character of *this*. If *this* is empty,
        -1 is returned. */
    lastIndex: func -> Int {
        return length() - 1
    }

    /** return the last character of *this*. */
    last: func -> Char {
        return this[lastIndex()]
    }

    /** return the index of the last occurence of *c* in *this*.
        If *this* does not contain *c*, return -1. */
    lastIndexOf: func(c: Char) -> Int {
        // could probably use reverse foreach here
        i := length()
        while(i) {
            if(this[i] == c) {
                return i
            }
            i -= 1
        }
        return -1
    }

    /** return a substring of *this* only containing the characters
        in the range ``start..length``.  */
    substring: func ~tillEnd (start: Int) -> This {
        len := length()

        if(start > len) {
            Exception new(This, "String.substring: out of bounds: length = %zd, start = %zd\n" format(len, start)) throw()
            return null
        }
        
        diff = (len - start) : SizeT
        sub := This new(diff)
        memcpy(sub, (this as Char*) + start, diff)
        sub[diff] = '\0'
        return sub
    }

    /** return a substring of *this* only containing the characters in the
        range ``start..end``. */
    substring: func (start, end: Int) -> This {
        len = this length() : Int

        if(start == end) return ""

        if(end < 0) {
            end = len + end + 1
        }

        if(start > len || start > end || end > len) {
            Exception new(This, "String.substring: out of bounds: length = %zd, start = %zd, end = %zd\n" format(len, start, end)) throw()
            return null
        }

        diff = (end - start) : Int
        sub := This new(diff)
        sub[diff] = 0
        memcpy(sub, (this as Char*) + start, diff)
        return sub
    }

    /** return a reversed copy of *this*. */
    reverse: func -> This {

        len := this length()

        if (!len) {
            return null
        }
        
        result := This new(len + 1)
        for (i: SizeT in 0..len) {
            result[i] = this[(len-1)-i]
        }
        result[len] = 0

        return result
    }

    /** print *this* to stdout without a following newline. Flush stdout. */
    print: func {
        printf("%s", this)
        fflush(stdout)
    }

    /** print *this* followed by a newline. */
    println: func {
        printf("%s\n", this)
    }

    /** return a string that contains *this*, repeated *count* times. */
    times: func (count: Int) -> This {
        length := length()
        result := gc_malloc((length * count) + 1) as Char*
        for(i in 0..count) {
            memcpy(result + (i * length), this, length)
        }
        result[length * count] = '\0';
        return result
    }

    /** return a copy of *this*. */
    clone: func -> This {
        length := length()
        copy := This new(length)
        memcpy(copy, this, length + 1)
        return copy
    }

    /** return a string that contains *this* followed by *other*. */
    append: func(other: This) -> This {
        length := length()
        rlength := other length()
        copy := This new(length + rlength) as Char*
        memcpy(copy, this, length)
        memcpy(copy + length, other, rlength + 1) // copy the final '\0'
        return copy
    }

    /** return a string containing *this* followed by *other*. */
    append: func ~char (other: Char) -> This {
        length := length()
        copy := This new(length + 1) as Char*
        memcpy(copy, this, length)
        copy[length] = other
        copy[length + 1] = '\0'
        return copy
    }

    /** return the number of *what*'s occurences in *this*. */
    count: func ~char (what: Char) -> Int {
        count := 0
        for(i: Int in 0..length()) {
            if(this[i] == what)
                count += 1
        }
        return count
    }

    /** return the number of *what*'s non-overlapping occurences in *this*. */
    count: func ~string (what: String) -> Int {
        length := this length()
        whatLength := what length()
        count := 0
        i := 0
        while(i < length) {
            if(compare(what, i, whatLength)) {
                count += 1
                i += whatLength
            } else {
                i += 1
            }
        }
        return count
    }

    /** clone myself, return all occurences of *oldie* with *kiddo* and return it. */
    replace: func (oldie, kiddo: Char) -> This {
        if(!contains(oldie)) return this

        length := length()
        copy := this clone()
        for(i in 0..length) {
            if(copy[i] == oldie) copy[i] = kiddo
        }
        return copy
    }

    /** clone myself, return all occurences of *oldie* with *kiddo* and return it. */
    replace: func ~string (oldie, kiddo: This) -> This {
        if(!contains(oldie)) return this

        length := length()
        oldieLength := oldie length()
        buffer := Buffer new(length)
        i: Int = 0
        while(i < length) {
            if(compare(oldie, i, oldieLength)) {
                // found oldie!
                buffer append(kiddo)
                i += oldieLength
            } else {
                // TODO optimize: don't append char by char, append chunk by chunk.
                buffer append((this as Char*)[i])
                i += 1
            }
        }
        buffer toString()
    }

    /** return a new string containg *other* followed by *this*. */
    prepend: func (other: This) -> This {
        other append(this)
    }
    
    /** return a new string containing *other* followed by *this*. */
    prepend: func ~char (other: Char) -> This {
        length := length()
        copy := This new(length + 1) as Char*
        copy[0] = other
        memcpy(copy + 1, this, length)
        return copy
    }

    /** return a new string with all characters lowercased (if possible). */
    toLower: func -> This {
        length := length()
        copy := This new(length) as Char*
        for(i in 0..length) {
            copy[i] = this[i] as Char toLower()
        }
        return copy
    }

    /** return a new string with all characters uppercased (if possible). */
    toUpper: func -> This {
        length := length()
        copy := This new(length) as Char*
        for(i in 0..length) {
            copy[i] = this[i] as Char toUpper()
        }
        return copy
    }

    /** return the character at position #*index* (starting at 0) */
    charAt: func(index: SizeT) -> Char {
        if(index < 0 || index > length()) {
            Exception new(This, "Accessing a String out of bounds index = %d, length = %d!" format(index, length())) throw()
        }
        (this as Char*)[index]
    }
    
    /** return a string formatted using *this* as template. */
    format: func (...) -> This {
        list:VaList

        va_start(list, this)
        
        length := vsnprintf(null, 0, this, list)
        output := This new(length)
        va_end(list)

        va_start(list, this)
        vsnprintf(output, length + 1, this, list)
        va_end(list)

        return output
    }
    
    iterator: func -> StringIterator<Char> {
        StringIterator<Char> new(this)
    }

}

operator == (str1: String, str2: String) -> Bool {
    return str1 equals(str2)
}

operator != (str1: String, str2: String) -> Bool {
    return !str1 equals(str2)
}

// FIXME: later. for now, it fails with "couldn't replace blah"

/*
operator [] (string: String, index: SizeT) -> Char {
    string charAt(index)
}

operator []= (string: String, index: SizeT, value: Char) {
    (string as Char*)[index] = value
}

operator [] (string: String, range: Range) -> String {
    string substring(range min, range max)
}
*/
         
operator * (str: String, count: Int) -> String {
    return str times(count)
}

operator + (left, right: String) -> String {
    return left append(right)
}

operator + (left: LLong, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: LLong) -> String {
    left + right toString()
}

operator + (left: Int, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: Int) -> String {
    left + right toString()
}

operator + (left: Bool, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: Bool) -> String {
    left + right toString()
}

operator + (left: Double, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: Double) -> String {
    left + right toString()
}

operator + (left: String, right: Char) -> String {
    left append(right)
}

operator + (left: Char, right: String) -> String {
    right prepend(left)
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
    
    in: func(range: Range) -> Bool {
        return this >= range min && this < range max
    }
}
    
Long:  cover from signed long  extends LLong
Short: cover from signed short extends LLong
Int:   cover from signed int   extends LLong {
	// temporary workaround until covers inheritance is duplication
	compareTo: func<T>(other: T) -> Int {
        (T == This) ? (this <=> other as This) : -1
    }
}

ULLong: cover from unsigned long long extends LLong {

    toString:    func -> String { "%llu" format(this) }
    
    in: func(range: Range) -> Bool {
        return this >= range min && this < range max
    }
    
}

ULong:  cover from unsigned long  extends ULLong
UInt:   cover from unsigned int   extends ULLong
UShort: cover from unsigned short extends ULLong


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

}

/**
 * iterators
 */
Iterator: abstract class <T> {

    hasNext: abstract func -> Bool
    next: abstract func -> T

    hasPrev: abstract func -> Bool
    prev: abstract func -> T

    remove: abstract func -> Bool

}

Iterable: abstract class <T> {

    iterator: abstract func -> Iterator<T>

    /** return the contents of the iterable as ArrayList. */
    toArrayList: func -> ArrayList<T> {
        result := ArrayList<T> new()
        for(elem: T in this) {
            result add(elem)
        }
        result
    }
    
}

/**
 * iterators
 */

StringIterator: class <T> extends Iterator<T> {

    i := 0
    str: String
    
    init: func ~withStr (=str) {}
    
    hasNext: func -> Bool {
        i < str length()
    }

    next: func -> T {
        c := str[i]
        i += 1
        return c
    }

    hasPrev: func -> Bool {
        i > 0
    }

    prev: func -> T {
        i -= 1
        return str[i]
    }
    
    remove: func -> Bool { false } // this could be implemented!
    
}

/**
 * exceptions
 */
Exception: class {

    origin: Class
    msg : String

    init: func ~originMsg (=origin, =msg) {}
    init: func ~noOrigin (=msg) {}
    
    crash: func {
        fflush(stdout)
        x := 0
        x = 1 / x
    }
    
    getMessage: func -> String {
        //max := const 1024
        max : const Int = 1024
        buffer := gc_malloc(max) as String
        if(origin) snprintf(buffer, max, "[%s in %s]: %s\n", this as Object class name, origin name, msg)
        else snprintf(buffer, max, "[%s]: %s\n", this as Object class name, msg)
        return buffer
    }
    
    print: func {
        fprintf(stderr, "%s", getMessage())
        printf("%s", getMessage())
    }
    
    throw: func {
        print()
        crash()
    }

}
