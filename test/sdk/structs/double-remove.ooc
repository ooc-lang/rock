import structs/[ArrayList]

main: func {
    a := [1, 2, 3] as ArrayList<Int>
    iter := a iterator()
    x := iter next()

    iter remove()
    try {
        iter remove()
    } catch {
        "All good!" println()
        exit(0)
    }

    // should never reach here
    "Woops, ArrayListIterator is unsafe..." println()
    exit(1)
}
