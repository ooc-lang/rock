import os/[Pipe, Process]
import structs/ArrayList

main: func {
    proc := Process new(["cat"] as ArrayList<String>)
    proc setStdin(Pipe new())
    for(i in 0..11111)
        proc stdIn write("meow\n")
    proc execute()
}
