include stdlib, stdint, stddef, float, ctype, sys/types

LLong: cover from signed long long {

    toString:    func -> String { numberToString(this, 10) }
    toHexString: func -> String { numberToString(this, 16) }

    odd?:  func -> Bool { this % 2 == 1 }
    even?: func -> Bool { this % 2 == 0 }

    divisor?: func (divisor: Int) -> Bool {
        this % divisor == 0
    }

    in?: func(range: Range) -> Bool {
        return this >= range min && this < range max
    }

    times: func (fn: Func) {
        for(i in 0..this) {
            fn()
        }
    }

    times: func ~withIndex (fn: Func(This)) {
        for (i in 0..this) {
            fn(i)
        }
    }

    abs: func -> This {
        return this >= 0 ? this : this * -1
    }
}

Long:  cover from signed long  extends LLong
Int:   cover from signed int   extends LLong
Short: cover from signed short extends LLong

ULLong: cover from unsigned long long extends LLong {

    toString:    func -> String { numberToString(this, 10) }

    in?: func(range: Range) -> Bool {
        return this >= range min && this < range max
    }

}

ULong:  cover from unsigned long  extends ULLong
UInt:   cover from unsigned int   extends ULLong
UShort: cover from unsigned short extends ULLong

//INT_MIN,    INT_MAX  : extern const static Int
//UINT_MAX           : extern const static UInt
//LONG_MIN,  LONG_MAX  : extern const static Long
//ULONG_MAX          : extern const static ULong
//LLONG_MIN, LLONG_MAX : extern const static LLong
//ULLONG_MAX             : extern const static ULLong

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

Octet:  cover from uint8_t
SizeT:  cover from size_t extends ULLong
SSizeT:  cover from ssize_t extends LLong
PtrDiff: cover from ptrdiff_t extends LLong

/**
 * real types
 */
LDouble: cover from long double {

    toString: func -> String {
        b := Buffer new (512)
        len := snprintf(b data, 512, "%.2Lf" toCString(), this)
        b setLength(len)
        b toString()
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


_conv_cypher := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
/**
    converts integral type num into a String with base base
    @author rofl0r
    @params num: number to convert
    @params base: i.e. 2 for binary, 10 for dec, 16 for hex
    @params maxLength: signal maximum length of returned string (will be incremented by one if negative, to have space for the "-")
        if 0, the algorithm chooses the maxLength.
    @params pad: pad with zeroes
*/
numberToString: func (num: UInt64, base: SizeT, maxLength: SizeT = 0, pad:= false) -> String {
    assert(base % 2 == 0)
    assert(base <= _conv_cypher size)
    myNum : UInt64
    _signed := false
    if ((num& as Int64*)@ < 0) {
        _signed = true
        tmp : Int64 = -num
        myNum = tmp
    } else myNum = num

    maxLen := 64 / (base / 2)
    if (maxLength != 0 && maxLength < maxLen) maxLen := maxLength
    len := maxLen

    result := Buffer new (len + (_signed ? 1 : 0))
    result setLength(len + (_signed ? 1 : 0))

    if (_signed) result shiftRight(1) // shift 1 so we have place for the minus char

    for (i in 0..len) result[i] = '0'

    while ((myNum > 0) && (len > 0)) {
        i := myNum % base
        result[len - 1] = _conv_cypher[i]
        myNum -= i
        len -= 1
        myNum /= base
    }
    if (!pad) {
        shr := 0
        for (i in 0..maxLen) {
            if (result[i] == '0') shr += 1
            else break
        }
        if (num == 0) shr -= 1
        result shiftRight(shr)
    }
    if (_signed) {
        result shiftLeft(1)
        result[0] = '-'
    }
    result toString()
}


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
