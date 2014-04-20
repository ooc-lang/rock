import ../[Thread], math, os/Time

include unistd

version(unix || apple) {

    /**
     * pthreads implementation of threads.
     */
    ThreadUnix: class extends Thread {

        pthread: PThread

        init: func ~unix (=_code) {}

        start: func -> Bool {
            result := pthread_create(pthread&, null, _code as Closure thunk, _code as Closure context)
            (result == 0)
        }

        wait: func -> Bool {
            result := pthread_join(pthread, null)
            (result == 0)
        }

        wait: func ~timed (seconds: Double) -> Bool {
            version (!(openbsd || apple)) {
                ts: TimeSpec
                __setupTimeout(ts&, seconds)
                    
                result := pthread_timedjoin_np(pthread, null, ts&)
                return (result == 0)
            }

            version (openbsd || apple) {
                return __fake_timedjoin(seconds)
            }
            false
        }

        alive?: func -> Bool {
            pthread_kill(pthread, 0) == 0
        }

        _currentThread: static func -> This {
            thread := This new(func {})
            thread pthread = pthread_self()
            thread
        }

        _yield: static func -> Bool {
            // pthread_yield is non-standard, use sched_yield instead
            // as a bonus, this works on OSX too.
            result := sched_yield()
            (result == 0)
        }

        // private stuff

        __setupTimeout: func (ts: TimeSpec@, seconds: Double) {
            // We need an absolute number of seconds since the epoch
            // First order of business - what time is it?
            tv: TimeVal
            gettimeofday(tv&, null)

            nowSeconds: Double = tv tv_sec as Double + tv tv_usec as Double / 1_000_000.0

            // Now compute the amount of seconds between January 1st, 1970 and the time
            // we will stop waiting on our thread
            absSeconds: Double = nowSeconds + seconds

            // And store it in a timespec, converting again...
            ts tv_sec = floor(absSeconds) as TimeT
            ts tv_nsec = ((absSeconds - ts tv_sec) * 1000 + 0.5) * (1_000_000 as Long)
        }

        /*
         * This is a semi-busywait implementation of timedjoin
         * The real solution is to use condition variables, but
         * I honestly don't have the courage to use them right now.
         */
        __fake_timedjoin: func (seconds: Double) -> Bool {
            while (seconds > 0.0) {
                Time sleepMilli(20)
                seconds -= 0.02
                if (!alive?()) {
                    // successfully joined
                    return true 
                }
            }
            false
        }

    }

    /* C interface */
    include pthread
    include sched

    PThread: cover from pthread_t
    TimeT: cover from time_t
    TimeSpec: cover from struct timespec {
        tv_sec: extern TimeT
        tv_nsec: extern Long
    }

    version (!(openbsd || apple)) {
        // Using proto here as defining '_GNU_SOURCE' seems to cause more trouble than anything else...
        pthread_timedjoin_np: extern proto func (thread: PThread, retval: Pointer, abstime: TimeSpec*) -> Int
    }

    version(gc) {
        pthread_create: extern(GC_pthread_create) func (threadPtr: PThread*, attrPtr: Pointer, startRoutine: Pointer, userArgument: Pointer) -> Int
        pthread_join:   extern(GC_pthread_join)   func (thread: PThread, retval: Pointer*) -> Int
    }
    version (!gc) {
        pthread_create: extern func (threadPtr: PThread*, attrPtr: Pointer, startRoutine: Pointer, userArgument: Pointer) -> Int
        pthread_join:   extern func (thread: PThread, retval: Pointer*) -> Int
    }
    pthread_kill: extern func (thread: PThread, signal: Int) -> Int
    pthread_self: extern func -> PThread
    sched_yield: extern func -> Int
}
