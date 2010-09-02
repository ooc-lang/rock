include stdlib

__LINE__: extern Int
__FILE__: extern CString
__FUNCTION__: extern CString

strcmp: extern func (Char*, Char*) -> Int
strncmp: extern func (Char*, Char*, Int) -> Int
strstr: extern func (Char*, Char*)
strlen:  extern func (Char*) -> Int

strtol:  extern func (Char*, Pointer, Int) -> Long
strtoll: extern func (Char*, Pointer, Int) -> LLong
strtoul: extern func (Char*, Pointer, Int) -> ULong
strtof:  extern func (Char*, Pointer)      -> Float
strtod:  extern func (Char*, Pointer)      -> Double
strtold: extern func (Char*, Pointer)      -> LDouble

/**
 * Character type
 */
Char: cover from char {

    /** check for an alphanumeric character */
    alphaNumeric?: func -> Bool {
        alpha?() || digit?()
    }

    /** check for an alphabetic character */
    alpha?: func -> Bool {
        lower?() || upper?()
    }

    /** check for a lowercase alphabetic character */
    lower?: func -> Bool {
        this >= 'a' && this <= 'z'
    }

    /** check for an uppercase alphabetic character */
    upper?: func -> Bool {
        this >= 'A' && this <= 'Z'
    }

    /** check for a decimal digit (0 through 9) */
    digit?: func -> Bool {
        this >= '0' && this <= '9'
    }

    /** check for an octal digit (0 through 7) */
    octalDigit?: func -> Bool {
        this >= '0' && this <= '7'
    }

    /** check for a hexadecimal digit (0 1 2 3 4 5 6 7 8 9 a b c d e f A B C D E F) */
    hexDigit?: func -> Bool {
        digit?() ||
        (this >= 'A' && this <= 'F') ||
        (this >= 'a' && this <= 'f')
    }

    /** check for a control character */
    control?: func -> Bool {
        (this >= 0 && this <= 31) || this == 127
    }

    /** check for any printable character except space */
    graph?: func -> Bool {
        printable?() && this != ' '
    }

    /** check for any printable character including space */
    printable?: func -> Bool {
        this >= 32 && this <= 126
    }

    /** check for any printable character which is not a space or an alphanumeric character */
    punctuation?: func -> Bool {
        printable?() && !alphaNumeric?() && this != ' '
    }

    /** check for white-space characters: space, form-feed ('\\f'), newline ('\\n'),
        carriage return ('\\r'), horizontal tab ('\\t'), and vertical tab ('\\v') */
    whitespace?: func -> Bool {
        this == ' '  ||
        this == '\f' ||
        this == '\n' ||
        this == '\r' ||
        this == '\t' ||
        this == '\v'
    }

    /** check for a blank character; that is, a space or a tab */
    blank?: func -> Bool {
        this == ' ' || this == '\t'
    }

    /** convert to an integer. This only works for digits, otherwise -1 is returned */
    toInt: func -> Int {
        if (digit?()) {
            return (this - '0') as Int
        }
        return -1
    }

    /** return the lowered character */
    toLower: extern(tolower) func -> This

    /** return the capitalized character */
    toUpper: extern(toupper) func -> This

    /** return a one-character string containing this character. */
    toString: func -> String {
        String new(this& as CString, 1)
    }

    /** write this character to stdout without a following newline. */
    print: func {
        fputc(this, stdout)
    }

    /** write this character to stdout, followed by a newline */
    println: func {
        fputc(this, stdout)
        fputc('\n', stdout)
    }

    containedIn?: func(s : String) -> Bool {
        containedIn?(s _buffer data, s size)
    }

    containedIn?: func ~charWithLength (s : Char*, sLength: SizeT) -> Bool {
        for (i in 0..sLength) {
            if ((s + i)@ == this) return true
        }
        return false
    }

    compareWith: func (compareFunc: Func (Char, Char*, SizeT) -> SSizeT, target: Char*, targetSize: SizeT) -> SSizeT {
        compareFunc(this, target, targetSize)
    }

}

SChar: cover from signed char extends Char
UChar: cover from unsigned char extends Char
WChar: cover from wchar_t

operator as (value: Char) -> String {
    value toString()
}

operator as (value: Char*) -> String {
    value ? value as CString toString() : null
}

operator as (value: CString) -> String {
    value ? value toString() : null
}

CString: cover from Char* {

    /** Create a new string exactly *length* characters long (without the nullbyte).
        The contents of the string are undefined. */
    new: static func~withLength (length: Int) -> This {
        result := gc_malloc(length + 1) as Char*
        result[length] = '\0'
        result as This
    }
        /** return a copy of *this*. */
    clone: func -> This {
        length := length()
        copy := This new(length)
        memcpy(copy, this, length + 1)
        return copy as This
    }

    equals?: func( other: This) -> Bool {
        if (other == null) return false
        l := length()
        for (i in 0..l) {
            if (( (this + i)@ != (other + i)@) || (other + i)@ == '\0') return false
        }
        return true
    }

    toString: func -> String { String new(this, length()) }

    /** return the string's length, excluding the null byte. */
    length: extern(strlen) func -> Int
    
}

operator == (str1: CString, str2: CString) -> Bool {
    if ((str1 == null) || (str2 == null)) return false
    str1 equals?(str2)
}

operator != (str1: CString, str2: CString) -> Bool {
    !(str1 == str2)
}


