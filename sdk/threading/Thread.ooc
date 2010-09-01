version (!windows) {
    import native/[ThreadUnix, MutexUnix, ThreadLocalUnix]
}
version (windows) {
    import native/[ThreadWin32, MutexWin32, ThreadLocalWin32]
}


/**
   A thread is a thread of execution in a program. Multiple threads
   can run concurrently, allowing parallel computations to occur.

   However, since such threads are preemptible, synchronization issues
   can occur, such as race conditions (two threads access the same memory
   location in an interleaved manner, leaving an inconsistent state)
   or

   :author: Amos Wenger (nddrylliog)
 */
Thread: abstract class {

    _code: Func

    /**
       Create a new thread that will run a given function.
       Note that this only creates the thread - the start() method
       can be used to effectively start execution of this thread.

       :param code: A function to be executed from the newly created
       thread. It can be a closure (and it's actually pretty convenient)
     */
    new: static func (._code) -> This {

        version (unix || apple) {
            return ThreadUnix new(_code) as This
        }
        version (windows) {
            return ThreadWin32 new(_code) as This
        }

        Exception new(This, "Unsupported platform!\n") throw()
        null

    }

    /**
       Starts the actual execution of a thread.

       This call is non-blocking, since the execution of this thread's
       code will happen concurrently.

       You can call wait() to block until the started thread has finished
       its job.
     */
    start: abstract func -> Int

    /**
       Blocks until this thread has finished running (ie. join this thread).
     */
    wait: abstract func -> Int

}

/**
   A mutex is a mechanism used for synchronizing threads.

   To avoid portions of code to be executed by several threads in parallel,
   potentially yielding incorrect results

   :author: Amos Wenger (nddrylliog)
 */
Mutex: abstract class {

    /**
       :return: an intialized mutex, unlocked.

       IMPORTANT: mutexes are special beasts. Don't attempt to access
       the class of a mutex. Depending on the underlying implementation,
       it may not be a real ooc object but only a pointer.
     */
    new: static func -> This {

        version (unix || apple) {
            return MutexUnix new()
        }
        version (windows) {
            return MutexWin32 new()
        }

        Exception new(This, "Unsupported platform!\n") throw()
        null

    }

    /**
       Destroy a mutex and its associated ressources.

       Don't call destroy() twice on the same mutex - doing that
       results in undefined behavior.
     */
    destroy: final func {
        ooc_mutex_destroy(this)
    }

    /**
       Acquire this mutex for the current thread. No other thread may
       acquire it until it's released (with the unlock() method)

       If this mutex is already locked from thread A, and lock() is
       called from thread B, then thread B will sleep until thread A
       calls unlock() on it.
     */
    lock: final func {
        // must be defined in native/
        ooc_mutex_lock(this)
    }

    /**
       Unlock this mutex, allowing other threads to acquire it.

       Don't try to unlock an already unlocked mutex - doing that
       results in undefined behavior
     */
    unlock: final func {
        // must be defined in native/
        ooc_mutex_unlock(this)
    }

}

/**
   A mutex is a mechanism used for synchronizing threads.
   A recursive mutex can be locked several times in a row. unlock() should be
   called as many times to properly unlock it.

   To avoid portions of code to be executed by several threads in parallel,
   potentially yielding incorrect results

   :author: Amos Wenger (nddrylliog)
 */
RecursiveMutex: abstract class {

    /**
       :return: an intialized mutex, unlocked.

       IMPORTANT: mutexes are special beasts. Don't attempt to access
       the class of a mutex. Depending on the underlying implementation,
       it may not be a real ooc object but only a pointer.
     */
    new: static func -> This {

        version (unix || apple) {
            return RecursiveMutexUnix new()
        }
        version (windows) {
            return RecursiveMutexWin32 new()
        }

        Exception new(This, "Unsupported platform!\n") throw()
        null

    }

    /**
       Destroy a mutex and its associated ressources.

       Don't call destroy() twice on the same mutex - doing that
       results in undefined behavior.
     */
    destroy: final func {
        ooc_recursive_mutex_destroy(this)
    }

    /**
       Acquire this mutex for the current thread. No other thread may
       acquire it until it's released (with the unlock() method)

       If this mutex is already locked from thread A, and lock() is
       called from thread B, then thread B will sleep until thread A
       calls unlock() on it.
     */
    lock: final func {
        // must be defined in native/
        ooc_recursive_mutex_lock(this)
    }

    /**
       Unlock this mutex, allowing other threads to acquire it.
     */
    unlock: final func {
        // must be defined in native/
        ooc_recursive_mutex_unlock(this)
    }

}

/*
    A ThreadLocal is a variable whose data is not shared by all threads
    (as it is for normal global variables), but each thread has got
    its own storage.

    :author: Friedrich Weber (fredreichbier)
 */
ThreadLocal: abstract class <T> {
    new: static func <T> -> This<T> {

        version (unix || apple) {
            return ThreadLocalUnix<T> new() as This
        }
        version (windows) {
            return ThreadLocalWin32<T> new() as This
        }
        Exception new(This, "Unsupported platform!\n") throw()
        null
    }

    /**
        Set the data.
     */
    set: abstract func (value: T)

    /**
        Get the data, obviously.
     */
    get: abstract func -> T

    /**
        Return true if there is any data set.
      */
    hasValue?: abstract func -> Bool
}
