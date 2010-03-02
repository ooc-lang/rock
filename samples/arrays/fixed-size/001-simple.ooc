
main: func {
 
    array: Int[3]
    for(i in 0..3)  array[i ] = i + 1
    for(i in 0..3) "array[%d] = %d" format(i, array[i]) println()
    
}