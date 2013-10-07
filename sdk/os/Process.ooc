
import Pipe
import structs/[List, ArrayList, HashMap]
import native/[ProcessUnix, ProcessWin32]

/**
 * Allows to launch processes with arbitrary arguments, redirect
 * standard input, output, and error, get the error code, and wait
 * for the end of the execution
 */
Process: abstract class {

    /**
       Arguments passed to the executable. The first argument
       should be the path to the executable.
     */
    args: List<String>

    /** Pipe to which standard output will be redirected if it's non-null */
    stdOut = null: Pipe
    /** Pipe to which standard input will be redirected if it's non-null */
    stdIn  = null: Pipe
    /** Pipe to which standard error will be redirected if it's non-null */
    stdErr = null: Pipe

    /** Environment variables that should be defined for the launched process */
    env = null : HashMap<String, String>

    /** Current working directory of the launched process */
    cwd = null : String

    /** PID of the child process */
    pid = 0: Long

    /**
       Create a new process from an array of arguments
     */
    new: static func ~fromArray (args: String[]) -> This {
        p := ArrayList<String> new()
        for (i in 0..args length) {
            arg := args[i]
            p add(arg)
        }
        new(p)
    }

    /**
       Create a new process from a list of arguments
     */
    new: static func (.args) -> This {
        version(unix || apple) {
            return ProcessUnix new(args) as This
        }
        version(windows) {
            return ProcessWin32 new(args) as This
        }
        Exception new(This, "os/Process is unsupported on your platform!") throw()
        null
    }

    /**
       Create a new process with given arguments and environment
       variables
     */
    new: static func ~withEnvFromArray (args: String[], .env) -> This {
        p := new(args)
        p env = env
        p
    }

    /**
       Create a new process with given arguments and environment
       variables.
     */
    new: static func ~withEnv (.args, .env) -> This {
        p := new(args)
        p env = env
        p
    }

    /** Terminate the child process with a SIGTERM signal */
    terminate: abstract func

    /** Terminate the child process with a SIGKILL signal. Like `terminate`, but more violent. */
    kill: abstract func

    setStdout: func(=stdOut){}
    setStdin:  func(=stdIn) {}
    setStderr: func(=stdErr) {}

    setEnv: func(=env) {}
    setCwd: func(=cwd) {}

    /** Execute the process and wait for it to end */
    execute: func -> Int {
        executeNoWait()
        wait()
    }

    /**
     * Wait for the process to end. Bad things will happen
     * if you haven't called `executeNoWait` before.
     */
    wait: abstract func -> Int

    /**
     * See if process has ended without hanging if it hasn't yet.
     * @return exit code, or -1 if process hasn't exited yet.
     *
     * Throws an Exception if can't wait for some reason.
     */
    waitNoHang: abstract func -> Int

    /**
     * Execute the process without waiting for it to end.
     * You have to call `wait` manually
     * @return child pid process.
     */
    executeNoWait: abstract func -> Long

    /**
     * Execute the process, and return all the output to stdout
     * as a string
     *
     * @return the standard output, and the exit code
     */
    getOutput: func -> (String, Int) {

        stdOut = Pipe new()
        exitCode := execute()

        result := PipeReader new(stdOut) readAll()

        stdOut close()
        stdOut = null

        (result, exitCode)

    }

    /**
     * Execute the process, and return all the output to stderr
     * as a string
     *
     * @return the error output, and the exit code
     */
    getErrOutput: func -> (String, Int) {

        stdErr = Pipe new()
        exitCode := execute()

        result := PipeReader new(stdErr) readAll()

        stdErr close()
        stdErr = null

        (result, exitCode)

    }

    /**
     * @return a representation of the command, escaped to some point.
     */
    getCommandLine: func -> String {
        args join(" ") replaceAll("\\", "\\\\")
    }

}

ProcessException: class extends Exception {

    init: super func

}

BadExecutableException: class extends ProcessException {

    init: super func

}

