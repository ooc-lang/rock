import structs/[HashMap, ArrayList]
import ../[Env, Process, wait, unistd, Pipe, PipeReader]
import PipeUnix

version(unix || apple) {

ProcessUnix: class extends Process {

    init: func ~unix (=args) {
        this executable = this args get(0)
        this args add(null) // execvp wants NULL to end the array
        buf = this args toArray() // ArrayList<String> => String*
        env = null
        cwd = null
    }

    /** Wait for the process to end. Bad things will happen if you haven't called `executeNoWait` before. */
    wait: func -> Int {
        status: Int
        result := -555
        if(stdIn != null) {
            stdIn close('w')
        }
        waitpid(-1, status&, null)
        if (WIFEXITED(status)) {
            result = WEXITSTATUS(status)
            if (stdOut != null) {
                stdOut close('w')
            }
            if (stdErr != null) {
                stdErr close('w')
            }
        }
        return result
    }

    /** Execute the process without waiting for it to end. You have to call `wait` manually. */
    executeNoWait: func {
        pid := fork()
        if (pid == 0) {
            if (stdIn != null) {
                stdIn close('w')
                dup2(stdIn as PipeUnix readFD, 0)
            }
            if (stdOut != null) {
                stdOut close('r')
                dup2(stdOut as PipeUnix writeFD, 1)
            }
            if (stdErr != null) {
                stdErr close('r')
                dup2(stdErr as PipeUnix writeFD, 2)
            }
            /* amend the environment if needed */
            if(this env) {
                for(key in this env getKeys()) {
                    Env set(key, env[key], true)
                }
            }
            /* set a new cwd? */
            if(cwd != null) {
                chdir(cwd)
            }
            /* run the stuff. */
            execvp(executable, buf)
        }
    }

}

}
