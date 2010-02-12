import os/Process
import structs/ArrayList

main: func {
    proc := Process new(["ls"] as ArrayList<String>)
    proc setCwd("/")
    proc execute()
}
