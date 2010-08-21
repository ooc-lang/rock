import os/mmap
import structs/[ArrayList,HashMap]
import os/error

BinarySeq transTable = HashMap<String, Int> new()
BinarySeq transTable["c"] = Char size
BinarySeq transTable["d"] = Double size
BinarySeq transTable["f"] = Float size
BinarySeq transTable["h"] = Short size
BinarySeq transTable["i"] = Int size
BinarySeq transTable["l"] = Long size
BinarySeq transTable["P"] = Pointer size

BinarySeq: class {

    data : UChar*
    size : SizeT
    index := 0
    transTable: static HashMap<String, Int>

    init: func ~withData (=size, d: UChar*) {
        init(size)
        index = size
        memcpy(data, d, size * UChar size)
    }

    init: func ~withSize (=size) {
        memsize := size * UChar size
        // at least 4096, and a multiple of 4096 that is bigger than memsize
        realsize := memsize + 4096 - (memsize % 4096)
        data = gc_malloc(realsize)

        version (linux || apple) {
            result := mprotect(data, realsize, PROT_READ | PROT_WRITE | PROT_EXEC)
            if(result != 0) {
                Exception new(This, "mprotect(%p, %zd) failed with code %d. Message = %s\n" format(data, realsize, result, strerror(errno))) throw()
            }
        }

        version (windows) {
            // TODO: it seems that it works fine under Windows XP+mingw+GCC4.5 without it
            // on the other hand, it returns false with it and throws the exception.
            // Does anyone have any clue what's going on? We can't use VirtualAlloc because
            // it would leak :x

            /*
            result := VirtualProtect(data, realsize, PAGE_READWRITE, null)
            if(!result) {
                Exception new(This, "VirtualProtect(%p, %zd) failed !\n" format(data, realsize)) throw()
            }
            */
        }

        version (!(linux || apple || windows)) {
            Exception new(This, "Closures aren't supported on your platform (yet) !") throw()
        }
    }

    append: func ~other (other: BinarySeq) -> BinarySeq {
        append(other data, other size)
    }

    append: func ~withLength (ptr: Pointer, ptrLength: SizeT) -> BinarySeq {
        memcpy(data + index, ptr, ptrLength)
        index += ptrLength
        return this
    }

    reset: func { index = 0 }

    print: func {
        for(i : Int in 0..index)
            printf("%.2x ", data[i])
        println()
    }

}

operator += (b1, b2 : BinarySeq) -> BinarySeq {
    b1 append(b2)
}

operator += <T> (b1 : BinarySeq, addon: T) -> BinarySeq {
    b1 append(addon& as Pointer, T size)
}
