import structs/ArrayList
import frontend/CommandLine

Rock: class {
    execName := static ""
}

main: func(args: ArrayList<String>) {
    "NDD WE DESPERATELY NEED YOU, GET ON IRC" println()
    return 1

    Rock execName = args[0]
    CommandLine new(args)
}
