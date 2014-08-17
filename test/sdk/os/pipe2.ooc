import os/[Pipe, Time], threading/Thread

main: func {
    pipe := Pipe new()

    reader := Thread new(||
        while (!pipe eof?()) {
            result := pipe read(128)
            if (result) result print()
        }
        pipe close('r')
    )

    writer := Thread new(||
        for (i in 0..10) {
            pipe write("Hello %d\n" format(i))
            Time sleepMilli(100)
        }
        pipe close('w')
    )

    reader start()
    writer start()
    
    reader wait()
    writer wait()

    "Pass!" println()
}
