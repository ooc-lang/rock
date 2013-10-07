import os/Pipe

main: func {
    pipe := Pipe new()

    pipe write("Hello")

    buf := Buffer new()
    pipe read(buf)

    pipe close()

    buf println()
}
