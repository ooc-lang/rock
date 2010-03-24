import Pipe, PipeReader
import structs/[List, ArrayList, HashMap]
import text/Buffer
import native/[ProcessUnix, ProcessWin32]

Process: abstract class {

    args: ArrayList<String>
    executable: String
    stdOut = null: Pipe
    stdIn  = null: Pipe
    stdErr = null: Pipe
    buf : String*
    env: HashMap<String, String>
    cwd: String

    new: static func (args: ArrayList<String>) -> This {
        version(unix || apple) {
            return ProcessUnix new(args) as This
        }
        version(windows) {
            return ProcessWin32 new(args) as This
        }
        Exception new(This, "Unsupported platform!\n") throw()
        null
    }

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

    /** Wait for the process to end. Bad things will happen if you haven't called `executeNoWait` before. */
    wait: abstract func -> Int

    /** Execute the process without waiting for it to end. You have to call `wait` manually. */
    executeNoWait: abstract func

    /**
     * Execute the process, and return all the output to stdout
     * as a string
     */
    getOutput: func -> String {

        stdOut = Pipe new()
        execute()

        result := PipeReader new(stdOut) toString()

        stdOut close('r'). close('w')
        stdOut = null

        result

    }

    /**
     * Execute the process, and return all the output to stderr
     * as a string
     */
    getErrOutput: func -> String {

        stdErr = Pipe new()
        execute()

        result := PipeReader new(stdErr) toString()

        stdErr close('r'). close('w')
        stdErr = null

        result

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
