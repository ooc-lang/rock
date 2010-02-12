import structs/ArrayList
import os/[Pipe, Process, PipeReader]

main: func {
    proc := Process new(["cat"] as ArrayList<String>)
    proc setStdin(Pipe new()) .setStdout(Pipe new())
    proc executeNoWait()
    stdout := null as String
    proc communicate("Hello World!", stdout&, null)
    "I received: %s" format(stdout) println()
}
