import structs/[HashMap, ArrayList, List]
import ../[Env, Process, wait, unistd, Pipe]
import PipeUnix

version(unix || apple) {

include errno, signal

errno : extern Int
SIGTERM: extern Int
SIGKILL: extern Int
SIGSEGV: extern Int
SIGABRT: extern Int

WNOHANG: extern Int

kill: extern func (Long, Int)
signal: extern func (Int, Pointer)

/**
 * Process implementation for *nix
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

    wait: func -> Int {
        _wait(0)
    }

    waitNoHang: func -> Int {
        _wait(WNOHANG)
    }

    /**
     * Wait for the process to end. Bad things will happen if you
     * haven't called `executeNoWait` before.
     */
    _wait: func (options: Int) -> Int {
        status: Int
        result := -1

        waitpid(pid, status&, options)
        err := errno

        if (status == -1) {
            errString := strerror(err)
            Exception new("Process wait(): %s" format(errString toString())) throw()
        }

        if (WIFEXITED(status)) {
            result = WEXITSTATUS(status)
        } else if(WIFSIGNALED(status)) {
            termSig := WTERMSIG(status)
            message := "Child received signal %d" format(termSig)

            match termSig {
                case SIGSEGV =>
                    message = message + " (Segmentation fault)"
                case SIGABRT =>
                    message = message + " (Abort)"
                case =>
                    // pffrt.
            }

            message = message + "\n"
            if (stdErr) {
                stdErr write(message)
            } else {
                stderr write(message)
            }

            /*
            if (termSig == SIGABRT) {
                // otherwise we'll hang
                "killing" println()
                kill()
                "killed!" println()
            }
            */
        }

        if (result != -1) {
            // process exited? close stuff.

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
                cArgs[i] = args[i] toCString()
            }
            cArgs[args getSize()] = null // null-terminated - makes sense

            signal(SIGABRT, sigabrtHandler)

            execvp(cArgs[0], cArgs)
            exit(errno) // don't allow the forked process to continue if execvp fails
        }
        return pid
    }

    sigabrtHandler: static func {
        "Got a sigabrt" println()
        exit(255)
    }

}

}
