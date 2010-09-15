import structs/[ArrayList, LinkedList], os/[Time, Coro]
import threading/Thread

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

schedulerMutex := Mutex new()

scheduler: func {
    if(!mainCoro isMain) mainCoro initializeMainCoro()

    while(true) {
        schedulerMutex lock()
        if(!newCoros empty?()) {
            info := newCoros removeAt(0)
            schedulerMutex unlock()
            
            newCoro := Coro new()
            coros add(newCoro)
            "Just added coro %p!" printfln(newCoro)
            oldCoro := currentCoro
            currentCoro = newCoro

            oldCoro startCoro(currentCoro, ||
                stackBase := currentCoro stack
                stackSize := currentCoro allocatedStackSize
                oldStackBase := GC_stackbottom
                // Adjust the stackbottom and add our Coro's stack as a root for the GC
                GC_stackbottom = stackBase
                GC_add_roots(stackBase, stackBase + stackSize)
                "Coro started!" println()
                info c()
                "Terminating a coro!" printfln()
                GC_stackbottom = oldStackBase
                GC_remove_roots(stackBase, stackBase + stackSize)
                terminate()
            )
            "Started coro yielded! " println()
            continue
        }

        if(coros empty?()) break // stop the scheduler
        
        coro := coros removeAt(0)
        schedulerMutex unlock()
        switchTo(coro)

        schedulerMutex lock()
        if(deadCoros contains?(coro)) {
            // dead for dead.
            deadCoros remove(coro)
        } else {
            // reschedule it
            coros add(coro)
        }
        schedulerMutex unlock()
    }
}

Channel: class <T> {

    queue := LinkedList<T> new()
    
    send: func (t: T) {
        "Sending %d" printfln(t as Int)
        queue add(t)
        while(queue size >= 100) {
            "Queue filled, yielding" println()
            yield()
        }
    }

    recv: func -> T {
        while(true) {
            if(!queue empty?()) {
                return queue removeAt(0)
            }
            "Queue empty, yielding" println()
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


