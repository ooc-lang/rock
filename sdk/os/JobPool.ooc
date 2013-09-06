
import os/System
import structs/ArrayList
import os/Process

/**
 * A job, ie. us waiting on an external process to finish.
 */

Job: class {

    process: Process

    init: func (=process) {
    }

    wait: func -> Int {
        code := process wait()
        onExit(code)
        code
    }

    onExit: func (code: Int) {
      // override at will
    }

}

/**
 * A pool of jobs, quite simply.
 */

JobPool: class {

    jobs := ArrayList<Job> new()
    parallelism := System numProcessors()

    init: func {
    }

    /**
     * Wait for a single job to finish.
     */
    waitOne: func -> Int {
        if (jobs empty?()) return 0

        jobs removeAt(0) wait()
    }

    /**
     * Wait for all jobs to finish. If any job has a non-zero
     * exit code, it will be returned here.
     */
    waitAll: func -> Int {
        exitCode := 0

        while (!jobs empty?()) {
            code := waitOne()
            if (code != 0) {
                exitCode = code
            }
        }

        exitCode
    }

    /**
     * Add a job to this queue.
     *
     * Beware, this call may block if we already have
     * too many jobs queued.
     */
    add: func (job: Job) -> Int {
        code := _maybeWait()
        jobs add(job)
        code
    }

    
    _maybeWait: func -> Int {
        if (jobs size < parallelism) {
            return 0 // all good, let's launch more!
        }

        waitOne()
    }


}

