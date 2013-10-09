import os/Channel

chan := make(Int)

go(||
    for (i in 0..5) {
        chan << i
        yield()
    }
    chan << -1
)

go(||
    for (i in 5..10) {
        chan << i
        yield()
    }
    chan << -1
)

go(||
    while (true) match (i := !chan) {
        case -1 =>
            break
        case =>
            "%d" printfln(i)
            yield
    }
)

