import os/[Pipe, Process]
import structs/ArrayList

main: func {
    proc := Process new(["cat"] as ArrayList<String>)
    proc setStdin(Pipe new())
    proc executeNoWait()
    for(i in 0..200000)
        proc stdIn write("meow\n")
    proc wait()
}
