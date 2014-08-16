
import os/System
import structs/ArrayList
import os/Process

/**
 * A job, ie. us waiting on an external process to finish.
 */

Job: class {

    process: Process

    init: func (=process)

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

    init: func

    /**
     * Wait for a single job to finish.
     */
    waitOne: func -> (Int, Job) {
        if (jobs empty?()) return (0, null)

        job := jobs removeAt(0)
        (job wait(), job)
    }

    /**
     * Wait for all jobs to finish. If any job has a non-zero
     * exit code, it will be returned here.
     */
    waitAll: func -> (Int, Job) {
        exitCode := 0

        while (!jobs empty?()) {
            (code, job) := waitOne()
            if (code != 0) {
                return (code, job)
            }
        }

        (exitCode, null)
    }

    /**
     * Add a job to this queue.
     *
     * Beware, this call may block if we already have
     * too many jobs queued.
     */
    add: func (job: Job) -> (Int, Job) {
        (code, waitedJob) := _maybeWait()
        jobs add(job)
        (code, waitedJob)
    }

    
    _maybeWait: func -> (Int, Job) {
        if (jobs size < parallelism) {
            return 0 // all good, let's launch more!
        }

        waitOne()
    }


}

