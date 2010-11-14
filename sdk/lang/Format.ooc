/*
 @author Martin Brandenburg
 @author Nick Markwell
 @author Scott Olson
 @author rofl0r

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
*/


InvalidFormatException: class extends Exception {
    init: func(msg :CString) { message = "invalid format string! \"" + msg == null ? "" : msg toString() + "\"" }
}

InvalidTypeException: class extends Exception {
    init: func (T: Class) { message = "invalid type %s passed to generic function!" format(T name) }
}


/* Text Formatting */
TF_ALTERNATE := 1 << 0
TF_ZEROPAD   := 1 << 1
TF_LEFT      := 1 << 2
TF_SPACE     := 1 << 3
TF_EXP_SIGN  := 1 << 4
TF_SMALL     := 1 << 5
TF_PLUS      := 1 << 6
TF_UNSIGNED  := 1 << 7

FSInfoStruct: cover {
    precision : Int
    fieldwidth : Int
    flags: SizeT
    base : Int
    bytesProcessed: SizeT

}

__digits: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
__digits_small: String = "0123456789abcdefghijklmnopqrstuvwxyz"


argNext: inline func<T> (va: VarArgsIterator*, T: Class) -> T {
    if (!va@ hasNext?()) InvalidFormatException new(null) throw()
    return va@ next(T)
}

m_printn: func <T> (res: Buffer, info: FSInfoStruct@, arg: T) {
    sign: Char = '\0'
    tmp: Char[36]
    digits := __digits
    size := info fieldwidth
    i := 0
    
    n: UInt32
    signed_n: Int32
    
    if(T size == 4) {
        n = arg as UInt32
        signed_n = arg as Int32
    } else {
        n = arg as UInt64
        signed_n = arg as Int64
    }

    /* Preprocess the flags. */

    if(info flags & TF_ALTERNATE && info base == 16) {
        res append('0')
        res append (info flags & TF_SMALL ? 'x' : 'X')
    }

    if(info flags & TF_SMALL) digits = __digits_small

    if(!(info flags & TF_UNSIGNED) && signed_n < 0) {
        sign = '-'
        n = -signed_n
    } else if(info flags & TF_EXP_SIGN) {
        sign = '+'
    }

    if(sign)
        size -= 1

    /* Find the number in reverse. */
    if(n == 0) {
        tmp[i] = '0'
        i += 1
    } else {
        while(n != 0) {
            tmp[i] = digits[n % info base]
            i += 1
            n /= info base
        }
    }

    /* Pad the number with zeros or spaces. */
    if(!(info flags & TF_LEFT))
        while(size > i) {
            size -= 1
            if(info flags & TF_ZEROPAD) res append('0')
            else res append (' ')
        }

    if(sign) res append(sign)

    /* Write any zeros to satisfy the precision. */
    while(i < info precision) {
        info precision -= 1
        res append('0')
    }

    /* Write the number. */
    while(i != 0) {
        i -= 1
        size -= 1
        res append(tmp[i])
    }

    /* Left align the numbers. */
    if(info flags & TF_LEFT)
        while(size > 0) {
            size -= 1
            res append(' ')
        }
}

getCharPtrFromStringType: func <T> (s : T) -> Char* {
    res : Char*
    match (T) {
        case String => res = s as String ? s as String toCString() : null
        case Buffer => res = s as Buffer ? s as Buffer toCString() : null
        case CString => res = s as Char*
        case Pointer => res = s as Char*
        case =>
            if(T size == Pointer size) {
                res = s as Char*
            } else {
                InvalidTypeException new(T) throw()
            }
    }
    return res
}

getSizeFromStringType: func<T> (s : T) -> SizeT {
    res : SizeT
    match (T) {
        case String => res = s as String _buffer size
        case Buffer => res = s as Buffer size
        case CString => res = s as CString length()
        case Pointer => res = s as CString length()
        case => InvalidTypeException new(T) throw()
    }
    return res
}

parseArg: func(res: Buffer, info: FSInfoStruct*, va: VarArgsIterator*, p: Char*) {
    info@ flags |= TF_UNSIGNED
    info@ base = 10
    mprintCall := true
    /* Find the conversion. */
    match(p@) {
        case 'i' =>
            info@ flags &= ~TF_UNSIGNED
        case 'd' =>
            info@ flags &= ~TF_UNSIGNED
        case 'u' =>
        case 'o' =>
            info@ base = 8
        case 'x' =>
            info@ flags |= TF_SMALL
            info@ base = 16
        case 'X' =>
            info@ base = 16
        case 'p' =>
            info@ flags |= TF_ALTERNATE | TF_SMALL
            info@ base = 16
        case 'f' =>
            // reconstruct the original format statement.
            // TODO let this do the real thing.
            mprintCall = false
            tmp := Buffer new()
            tmp append('%')
            if(info@ flags & TF_ALTERNATE)
                tmp append('#')
            else if(info@ flags & TF_ZEROPAD)
                tmp append('0')
            else if (info@ flags & TF_LEFT)
                tmp append('-')
            else if (info@ flags & TF_SPACE)
                tmp append(' ')
            else if (info@ flags & TF_EXP_SIGN)
                tmp append('+')
            if (info@ fieldwidth != 0)
                tmp append(info@ fieldwidth toString())
            if (info@ precision != 0)
                tmp append("." + info@ precision toString())
            tmp append("f")
            res append(tmp toString() cformat(argNext(va, Float) as Float))
            
        case 'c' =>
            mprintCall = false
            i := 0
            if(!(info@ flags & TF_LEFT))
                while(i < info@ fieldwidth) {
                    i += 1
                    res append(' ')
                }
            res append(argNext(va, Char) as Char)
            while(i < info@ fieldwidth) {
                i += 1
                res append(' ')
            }
        case 's' =>
            mprintCall = false
            T := va@ getNextType()
            s : T = argNext(va, T)
            sval: Char* = getCharPtrFromStringType(s)
            if(sval) {
                /* Change to -2 so that 0-1 doesn't cause the
                 * loop to keep going. */
                if(info@ precision == -1) info@ precision = -2
                while((sval@) && (info@ precision > 0 || info@ precision <= -2)) {
                    if(info@ precision > 0) {
                        info@ precision -= 1
                    }
                    res append(sval@)
                    sval += 1
                }
            } else {
                res append("(nil)")
            }
        case '%' =>
                res append('%')
                   mprintCall = false
        case => mprintCall = false
    }
    if(mprintCall) {
        T := va@ getNextType()
        m_printn(res, info, argNext(va, T))
    }
}

getEntityInfo: inline func (info: FSInfoStruct@, va: VarArgsIterator*, start: Char*, end: Pointer) {

    /* save original pointer */
    p := start

    checkedInc := func {
        if (p < end) p += 1
        else InvalidFormatException new(start) throw()
    }

    /* Find any flags. */
    info flags = 0

    while(p as Pointer < end) {
        checkedInc()
        match(p@) {
            case '#' => info flags |= TF_ALTERNATE
            case '0' => info flags |= TF_ZEROPAD
            case '-' => info flags |= TF_LEFT
            case ' ' => info flags |= TF_SPACE
            case '+' => info flags |= TF_EXP_SIGN
            case => break
        }
    }

    /* Find the field width. */
    info fieldwidth = 0
    while(p@ digit?()) {
        if(info fieldwidth > 0)
            info fieldwidth *= 10
        info fieldwidth += (p@ as Int - 0x30)
        checkedInc()
    }

    /* Find the precision. */
    info precision = -1
    if(p@ == '.') {
        checkedInc()
        info precision = 0
        if(p@ == '*') {
            T := va@ getNextType()
            info precision = argNext(va, T) as Int
            checkedInc()
        }
        while(p@ digit?()) {
            if (info precision > 0)
                info precision *= 10
            info precision += (p@ as Int - 0x30)
            checkedInc()
        }
    }

    /* Find the length modifier. */
    while (p@ == 'l' || p@ == 'h' || p@ == 'L') checkedInc()

    info bytesProcessed = p as SizeT - start as SizeT
}


format: func~main <T> (fmt: T, args: ... ) -> T {
    if (args count == 0) return fmt
    res := Buffer new(512)
    va := args iterator()
    ptr := getCharPtrFromStringType(fmt)
    end : Pointer = (ptr as SizeT + getSizeFromStringType(fmt) as SizeT) as Pointer
    while (ptr as Pointer < end) {
        if (!va hasNext?()) {
            res append(ptr, (end - ptr as Pointer) as SizeT)
            break
        }
        match (ptr@) {
            case '%' => {
                info: FSInfoStruct
                getEntityInfo(info&, va&, ptr, end)
                ptr += info bytesProcessed
                parseArg(res, info&, va&, ptr)
            }
            case => res append(ptr@)
        }
        ptr += 1
    }
    result: T
    match (T) {
        case String => result = res toString()
        case Buffer => result = res
        case => result = res toCString()
    }
    return result
}


extend Buffer {
    format: func(args: ...) {
        setBuffer(format~main(this, args))
    }
}

extend String {
    format: func(args: ...) -> This {
        format~main(this, args)
    }

    printf: func(args: ...) {
        format~main(this, args) print()
    }

    printfln: func(args: ...) {
        format~main(this, args) println()
    }
}
