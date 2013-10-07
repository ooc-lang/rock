import os/Pipe

main: func {
    pipe := Pipe new()

    pipe write("Hello")
    pipe read(128) println()
    pipe close('r'). close('w')
}
