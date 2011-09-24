import structs/[HashMap, ArrayList, List]
import ../[Env, Process, wait, unistd, Pipe, PipeReader]
import PipeUnix

version(unix || apple) {

include errno, signal

errno : extern Int
SIGTERM: extern Int
SIGKILL: extern Int

kill: extern func (Long, Int)

/**
   Process implementation for *nix

   :author: Yannic Ahrens (showstopper)
   :author: Amos Wenger (nddrylliog)
 */
ProcessUnix: class extends Process {

    init: func ~unix (=args) {}

    /** terminate my child pid! */
    terminate: func {
        if(pid)
            kill(pid, SIGTERM)
    }

    kill: func {
        if(pid)
            kill(pid, SIGKILL)
    }

    /**
       Wait for the process to end. Bad things will happen if you
       haven't called `executeNoWait` before.
     */
    wait: func -> Int {
        status: Int
        result := -555
        if(stdIn != null) {
            stdIn close('w')
        }
        waitpid(-1, status&, 0)
        pid = status
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

    /**
       Execute the process without waiting for it to end.
       You have to call `wait` manually.
    */
    executeNoWait: func -> Long {

        pid = fork()
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
            if(env) {
                for(key in env getKeys()) {
                    Env set(key, env[key], true)
                }
            }

            /* set a new cwd? */
            if(cwd != null) {
                chdir(cwd as CString)
            }

            /* run the stuff. */
            cArgs : CString * = gc_malloc(Pointer size * (args getSize() + 1))
            for(i in 0..args getSize()) {
//            args getSize() times(|i| // FIXME: Yes, I'd really like to do a closure here, but it breaks cross-platform awesomess. Yes really.
                cArgs[i] = args[i] toCString()
            }
            cArgs[args getSize()] = null // null-terminated - makes sense

            execvp(cArgs[0], cArgs)
            exit(errno) // don't allow the forked process to continue if execvp fails
        }
        return pid
    }

}

}
