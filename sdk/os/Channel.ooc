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

GC_add_roots: extern func (Pointer, Pointer)
GC_remove_roots: extern func (Pointer, Pointer)
GC_stackbottom: extern Pointer

scheduler: func {
    mainCoro initializeMainCoro()

    while(true) {
        if(coros empty?() && newCoros empty?()) break
        
        i := 0
        for(coro in coros) {
            //"Main coro %p dispatching to coro %p, %d/%d" printfln(mainCoro, coro, i + 1, coros size())
            switchTo(coro)
            if(!deadCoros empty?() || !newCoros empty?()) {
                //"Dead coros / new coros, breaking!" println()
                break
            }
            i += 1
        }

        if(!newCoros empty?()) {
            //"Adding %d new coros" printfln(newCoros size())
            for(info in newCoros)  {
                //"Adding coro!" println()
                newCoro := Coro new()
                coros add(newCoro)
                oldCoro := currentCoro
                currentCoro = newCoro

                oldCoro startCoro(currentCoro, ||
                    stackBase := currentCoro stack
                    stackSize := currentCoro allocatedStackSize
                    oldStackBase := GC_stackbottom
                    // Adjust the stackbottom and add our Coro's stack as a root for the GC
                    GC_stackbottom = stackBase
                    GC_add_roots(stackBase, stackBase + stackSize)
                    //"Coro started!" println()
                    info c()
                    //"Terminating a coro!" printfln()
                    GC_stackbottom = oldStackBase
                    GC_remove_roots(stackBase, stackBase + stackSize)
                    terminate()
                )
            }
            newCoros clear()
        }

        if(!deadCoros empty?()) {
            //"Cleaning up %d dead coros" printfln(deadCoros size())
            for(deadCoro in deadCoros) { coros remove(deadCoro) }
            deadCoros clear()
        }
    }
}

Channel: class <T> {

    queue := LinkedList<T> new()
    //queue := ArrayList<T> new()

    send: func (t: T) {
        //"Sending %d" printfln(t as Int)
        queue add(t)
        while(queue size() > 100) {
            //"Queue filled, switching to %p. (Coro = %p)" printfln(mainCoro, currentCoro)
            yield()
        }
    }

    recv: func -> T {
        while(true) {
            if(!queue empty?()) {
                val := queue removeAt(0)
                return val
            }
            //"Queue empty, switching to %p. (Coro = %p)" printfln(mainCoro, currentCoro)
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
    switchTo(mainCoro)
}

switchTo: func (newCoro: Coro) {
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


