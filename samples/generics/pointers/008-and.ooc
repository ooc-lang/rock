
main: func {
    printf("%d == %d\n", 42, id(42))
    printf("%d == %d\n", 42, id2(42))
}

id: func <T> (t: T) -> T {
    data: T* = gc_malloc(T size)
    memcpy(data, t&, T size)
    return data[0]
}

id2: func <T> (t: T) -> T {
    data: T* = gc_malloc(T size)
    memcpy(data, t&, T size)
    return data@
}
