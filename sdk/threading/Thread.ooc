import native/[ThreadUnix, ThreadWin32]
import native/[MutexUnix, MutexWin32]
import native/[ThreadLocalUnix, ThreadLocalWin32]

/**
 * A thread is a thread of execution in a program. Multiple threads
 * can run concurrently, allowing parallel computations to occur.
 *
 * However, since such threads are preemptible, synchronization issues
 * can occur, such as race conditions (two threads access the same memory
 * location in an interleaved manner, leaving an inconsistent state)
 * or
 */
Thread: abstract class {

    _code: Func

    /**
     * Create a new thread that will run a given function.
     * Note that this only creates the thread - the start() method
     * can be used to effectively start execution of this thread.
     *
     * @param code A function to be executed from the newly created
     * thread. It can be a closure (and it's actually pretty convenient)
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
     * Starts the actual execution of a thread.
     *
     * This call is non-blocking, since the execution of this thread's
     * code will happen concurrently.
     *
     * You can call wait() to block until the started thread has finished
     * its job.
     *
     * @return true if the thread has started successfully, false otherwise
     */
    start: abstract func -> Bool

    /**
     * Blocks until this thread has finished running (ie. join this thread).
     *
     * @return true if the thread has successfully joined, ie. if it's finished running.
     * otherwise, false - the thread is not joinable, is already dead, a deadlock was
     * detected, etc.
     */
    wait: abstract func -> Bool

    /**
     * Similar to wait, but waits at most `seconds` for the thread to wrap it up.
     *
     * @param seconds Number of seconds to wait until we give up and stop waiting
     * for the thread to finish
     * @return true if the thread has finished while we were waiting, false if it is
     * still running.
     */
    wait: abstract func ~timed (seconds: Double) -> Bool

    /**
     * @return true if the thread is still running, false otherwise
     */
    alive?: abstract func -> Bool

    /**
     * @return the thread that's currently running
     */
    currentThread: static func -> This {
      version (unix || apple) {
        return ThreadUnix _currentThread()
      }
      version (windows) {
        return ThreadWin32 _currentThread()
      }
      null
    }

    /**
     * Causes the calling thread to relinquish the CPU. The
     * thread is moved to the end of the queue for its static
     * priority and a new thread gets to run.
     *
     * @return true on success, false on failure
     */
    yield: static func -> Bool {
      version (unix || apple) {
        return ThreadUnix _yield()
      }
      version (windows) {
        return ThreadWin32 _yield()
      }

      false
    }

}

/**
 * A mutex is a mechanism used for synchronizing threads.
 *
 * To avoid portions of code to be executed by several threads in parallel,
 * potentially yielding incorrect results
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

    with: final func (f: Func) {
        lock()
        f()
        unlock()
    }

}

/**
 * A mutex is a mechanism used for synchronizing threads.
 * A recursive mutex can be locked several times in a row. unlock() should be
 * called as many times to properly unlock it.
 *
 * To avoid portions of code to be executed by several threads in parallel,
 * potentially yielding incorrect results
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

    with: final func (f: Func) {
        lock()
        f()
        unlock()
    }

}

/**
 * A ThreadLocal is a variable whose data is not shared by all threads
 * (as it is for normal global variables), but each thread has got
 * its own storage.
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

    new: static func ~withVal <T> (val: T) -> This <T> {
        instance := This<T> new()
        instance set(val)
        instance
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
