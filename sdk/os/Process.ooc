import Pipe, PipeReader
import structs/[List, ArrayList, HashMap]
import native/[ProcessUnix, ProcessWin32]

/**
   Allows to launch processes with arbitrary arguments, redirect
   standard input, output, and error, get the error code, and wait
   for the end of the execution

   @author Yannic Ahrens (showstopper)
   @author Amos Wenger (nddrylliog)
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

    /**
       Create a new process from an array of arguments
     */
    new: static func ~fromArray (args: String[]) -> This {
        p := ArrayList<String> new()
        for (i in 0..args length) {
            s := args[i]
            p add(s)
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
        Exception new(This, "Unsupported platform!\n") throw()
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

        result := PipeReader new(stdOut) toString()

        stdOut close('r'). close('w')
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

        result := PipeReader new(stdErr) toString()


        stdErr close('r'). close('w')
        stdErr = null

        (result, exitCode)

    }

    /**
     * Send `data` to the process, wait for the process to end and get the
     * stdout and stderr data. You have to do `setStdIn(Pipe new())`/
     * `setStdOut(Pipe new())`/`setStdErr(Pipe new())`
     * before in order to send / get the data. You have to run `executeNoWait` before.
     * You can pass null as data, stdoutData or stderrData.
     */
    communicate: func (data: String, stdoutData, stderrData: String*) -> Int {

        /* send data to stdin */
        if(data != null) {
            written := 0
            while(written < data length())
                written += stdIn write(data)
        }

        /* wait for the process */
        result := wait()

        /* get the data */
        if(stdoutData != null)
            stdoutData@ = PipeReader new(stdOut) toString()
        if(stderrData != null)
            stderrData@ = PipeReader new(stdErr) toString()

        result

    }
}
