import structs/Array

main: func {

    size := 4
    arr := Array<Int> new(size)
    
    for(i in 0..2) {
        arr set(i, i)
    }
    for(i in 0..size) {
        //arr[i] = i
        arr set(i, i)
    }
    
    "==============" println()
    
    for(i in 0..size) {
        printf("%d = %d\n", i, arr get(i))
    }
    
    "==============" println()
    
    for(i in 0..size) {
        printf("%d = %d\n", i, arr[i])
    }
    
    "==============" println()

    i := 0
    iter := arr iterator()
    while(iter hasNext()) {
        printf("%d = %d\n", i, iter next())
        i += 1
    }
    
}