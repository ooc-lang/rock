
import os/Process

/**
 * A job, ie. us waiting on an external process to finish.
 *
 * :author: Amos Wenger (nddrylliog)
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

