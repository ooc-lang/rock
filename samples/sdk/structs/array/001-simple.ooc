import structs/Array

main: func {

    size := 12
    arr := Array<Int> new(size)
    
    for(i in 0..size / 2) {
        arr set(i, i + 1)
    }
    for(i in 0..size) {
        arr[i] = i + 1
    }
    
    for(i in 0..size) {
        printf("%d, ", arr get(i))
    }
    println()
    
    for(i in 0..size) {
        printf("%d, ", arr[i])
    }
    println()

    i := 0
    iter := arr iterator()
    while(iter hasNext()) {
        printf("%d, ", iter next())
        i += 1
    }
    println()
    
    for(i in arr) {
        printf("%d, ", i)
    }
    println()
    
}