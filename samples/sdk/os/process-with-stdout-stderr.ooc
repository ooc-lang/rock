import structs/ArrayList
import os/[Pipe, Process, PipeReader]

main: func {
    proc := Process new(["./test"] as ArrayList<String>)
    stdout := Pipe new()
    stderr := Pipe new()
    proc setStdout(stdout) .setStderr(stderr)
    proc execute()
    "STDOUT: %s" format(PipeReader new(stdout) toString()) println()
    "STDERR: %s" format(PipeReader new(stderr) toString()) println()
}
