include stdlib, stdint, stddef, float, ctype, sys/types
version(windows) {
    include limits
}

LLong: cover from signed long long {

    toString:    func -> String { "%lld" format(this as LLong) }
    toHexString: func -> String { "%llx" format(this as LLong) }

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
Int:   cover from signed int   extends LLong {
    toString:    func -> String { "%d" format(this) }
}
Short: cover from signed short extends LLong

ULLong: cover from unsigned long long extends LLong {

    toString:    func -> String { "%llu" format(this as ULLong) }

    in?: func(range: Range) -> Bool {
        return this >= range min && this < range max
    }

}

ULong:  cover from unsigned long  extends ULLong
UInt:   cover from unsigned int   extends ULLong {
    toString:    func -> String { "%u" format(this) }
}
UShort: cover from unsigned short extends ULLong

SHRT_MIN, SHRT_MAX: extern static Short
USHRT_MAX: extern static UShort
INT_MIN, INT_MAX: extern static Int
UINT_MAX: extern static UInt
LONG_MIN, LONG_MAX: extern static Long
ULONG_MAX: extern static ULong
LLONG_MIN, LLONG_MAX: extern static LLong
ULLONG_MAX: extern static ULLong

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
SSizeT:  cover from ssize_t extends LLong {
    toString:    func -> String { "%u" format(this) }
}
PtrDiff: cover from ptrdiff_t extends SSizeT

/**
 * real types
 */
LDouble: cover from long double {

    toString: func -> String {
        "%.2Lf" format(this)
    }

    abs: func -> This {
        return this < 0 ? -this : this
    }

}
Double: cover from double extends LDouble {
    toString: func -> String {
        "%.2f" format(this)
    }
}
Float: cover from float extends LDouble {
    toString: func -> String {
        "%.2f" format(this)
    }
}

FLT_MIN, FLT_MAX: extern static Float
DBL_MIN, DBL_MAX, INFINITY, NAN: extern static Double
LDBL_MIN, LDBL_MAX: extern static LDouble

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
