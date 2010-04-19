import structs/ArrayList
import frontend/CommandLine

Rock: class {
    execName := static ""
}

main: func(args: ArrayList<String>) {
    Rock execName = args[0]
    CommandLine new(args)
}
