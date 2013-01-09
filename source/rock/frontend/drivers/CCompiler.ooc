
// sdk stuff
import io/File
import os/[Process, Pipe, ShellUtils]
import structs/[List, ArrayList]

// our stuff
import Flags
import rock/frontend/BuildParams

CCompiler: class {

    executableName: String
    params: BuildParams

    init: func (=params) {
        executableName = "gcc"
    }

    setExecutable: func (=executableName) {
    }

    findExecutable: func (executableName: String) -> String {
        executablePath: String
        execFile := File new(executableName)

        if (!execFile exists?()) {
            execFile = ShellUtils findExecutable(executableName, false)
            if (execFile == null) {
                execFile = ShellUtils findExecutable(executableName + ".exe", false)
                if (execFile == null) {
                    execFile = ShellUtils findExecutable(executableName, true)
                }
            }
            executablePath = execFile name()
        } else {
            // If we initially got an existing compiler path, just use this one.
            executablePath = execFile getAbsoluteFile() getPath()
        }

        executablePath
    }

    launchCompiler: func (flags: Flags) -> Process {
        _launch(flags, executableName, false)
    }

    launchLinker: func (flags: Flags, linker: String) -> Process {
        if (!linker) {
            linker = executableName
        }
        _launch(flags, linker, true)
    }


    _launch: func (flags: Flags, executable: String, link: Bool) -> Process {
        // build the command line
        command := ArrayList<String> new()
        command add(findExecutable(executable))
        flags apply(command, link)
        command = command map(|a| a trim("\t ")) \
                          filter(|a| a != "")

        // create the necessary directories
        parent := File new(flags outPath) parent()
        if(!parent exists?()) {
            if(params verbose) "Creating path %s" format(parent getPath()) println()
            parent mkdirs()
        }

        // display the command line if needed
        if (params verbose) {
            command map(|arg| arg replaceAll("\\", "\\\\")) join(" ") println()
        }

        // actually launch the command
        proc := Process new(command)
        if (!params verbose) {
            proc setStderr(Pipe new())
        }
        proc executeNoWait()
        proc
    }
}
