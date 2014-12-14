import os/System
import threading/Thread
import structs/ArrayList

ThreadPool: class{
    pool: ArrayList<Thread> = ArrayList<Thread> new()
    lock: Mutex = Mutex new()
    parallelism := System numProcessors()

    init: func

    add: func(t: Thread, start: Bool = true){
        _shouldWait()
        lock lock()
        pool add(t)
        lock unlock()
        if(start) t start()
    }

    startAll: func {
        for(p in pool){
            p start()
        }
    }

    waitAll: func -> Bool{
        isSuc := true
        while(!pool empty?()){
            if(!waitFirst()) isSuc = false
        }
        isSuc
    }

    waitFirst: func -> Bool{
        if(pool empty?()) return true
        lock lock()
        currentThread := pool removeAt(0)
        lock unlock()
        currentThread wait()
    }

    clearPool: func{
        lock lock()
        for(p in pool){
            if(!p alive?()){
                pool remove(p)
            }
        }
        lock unlock()
    }

    _shouldWait: func -> Bool {
        clearPool()
        if(pool size < parallelism) return false

        waitFirst()
    }

    destroy: func{
        lock destroy()
    }
}
