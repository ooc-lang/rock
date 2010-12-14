import structs/[ArrayList, LinkedList], os/Time, os/Coro

coros := LinkedList<Coro> new()
deadCoros := LinkedList<Coro> new()

CoroStartInfo: class {
    c: Func
    init: func (=c) {}
}
newCoros  := LinkedList<CoroStartInfo> new()

mainCoro := Coro new()
currentCoro := mainCoro

atexit(scheduler)

scheduler: func {
    mainCoro initializeMainCoro()

    while(true) {
        if(coros empty?() && newCoros empty?()) break
        
        i := 0
        for(coro in coros) {
            //"Main coro %p dispatching to coro %p, %d/%d" printfln(mainCoro, coro, i + 1, coros getSize())
            switchTo(coro)
            if(!deadCoros empty?() || !newCoros empty?()) {
                //"Dead coros / new coros, breaking!" println()
                break
            }
            i += 1
        }

        if(!newCoros empty?()) {
            //"Adding %d new coros" printfln(newCoros getSize())
            for(info in newCoros)  {
                newCoro := Coro new()
                coros add(newCoro)
                //"Just added coro %p!" printfln(newCoro)
                oldCoro := currentCoro
                currentCoro = newCoro

                oldCoro startCoro(currentCoro, ||
                    //"Coro started!" println()
                    info c()
                    //"Terminating a coro!" printfln()
                    terminate()
                )
            }
            newCoros clear()
        }

        if(!deadCoros empty?()) {
            //"Cleaning up %d dead coros" printfln(deadCoros getSize())
            for(deadCoro in deadCoros) { coros remove(deadCoro) }
            deadCoros clear()
        }
    }
}

Channel: class <T> {

    queue := LinkedList<T> new()
    
    send: func (t: T) {
        //"Sending %d" printfln(t as Int)
        queue add(t)
        while(queue size >= 100) {
            //"Queue filled, yielding"
            yield()
        }
    }

    recv: func -> T {
        while(true) {
            if(!queue empty?()) {
                val := queue removeAt(0)
                return val
            }
            //"Queue empty, yielding"
            yield()
        }
        // yay hacks
        null
    }

}

operator << <T> (c: Channel<T>, t: T) {
    c send(t)
}

operator ! <T> (c: Channel<T>) -> T {
    c recv()
}

terminate: func {
    deadCoros add(currentCoro)
    yield()
}

yield: func {
    //"Yield!" println()
    switchTo(mainCoro)
}

switchTo: func (newCoro: Coro) {
    //"Switching from %p to %p" printfln(currentCoro, newCoro)
    oldCoro := currentCoro
    currentCoro = newCoro
    oldCoro switchTo(currentCoro)
}

go: func (c: Func) {
    newCoros add(CoroStartInfo new(c))
}

make: func <T> (T: Class) -> Channel<T> {
    Channel<T> new()
}
