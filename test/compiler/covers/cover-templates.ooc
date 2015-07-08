
use sam-assert

describe("A cover template-based version of array", ||

    ints := MyArray<Int> new(4)
    ints[0] = 1
    ints[1] = 2
    ints[2] = 3
    ints[3] = 4

    "Regular foreach: " println()
    for (i in 0..ints length) {
        expect(i + 1, ints[i])
    }

    "each(): " println()
    j := 1
    ints each(|n|
        expect(j, n)
        j += 1
    )

    ants := MyArray<Int> new(2)
    ants[0] = 5
    ants[1] = 6

    unts := ints + ants

    "unts each(): " println()
    j = 1
    unts each(|n|
        expect(j, n)
        j += 1
    )

)

// Support code

/**
 * With template, everything is inlined - the struct
 * type is written inline, the methods become macros,
 * so there should be no symbol conflict
 */
MyArray: cover template <T> {
    length: Int
    data: T*

    init: func@ (=length) {
        data = gc_malloc(T size * length)
    }

    get: func (index: Int) -> T {
        _checkIndex(index)
        data[index]
    }

    set: func@ (index: Int, value: T) {
        _checkIndex(index)
        data[index] = value
    }

    _checkIndex: func (index: Int) {
        if (index < 0 || index >= length) {
            Exception new("Out of bounds array access: %d should be in %d..%d" \
                format(index, 0, length)) throw()
        }
    }

    operator [] (i: Int) -> T {
        get(i)
    }

    operator []= (i: Int, v: T) {
        set(i, v)
    }

    operator + (other: This<T>) -> This<T> {
        append(other)
    }

    append: func (other: This<T>) -> This<T> {
        result := This<T> new(length + other length)

        i := 0
        doAppend := func (vavavouey: T) {
            result[i] = vavavouey
            i += 1
        }

        each(|vignoble| doAppend(vignoble))
        other each(|valery| doAppend(valery))
        result
    }

    each: func (f: Func (T)) {
        for (i in 0..length) {
            f(this[i])
        }
    }
}

