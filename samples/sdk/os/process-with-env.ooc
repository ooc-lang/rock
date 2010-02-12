import os/Pipe, os/Process, os/Env
import structs/[ArrayList, HashMap]

main: func() {
    env := HashMap<String> new()
    env put("HELLO_THERE", "I AM A BANANA")
    proc := Process new(["env"] as ArrayList<String>, env)
    proc execute()
}
