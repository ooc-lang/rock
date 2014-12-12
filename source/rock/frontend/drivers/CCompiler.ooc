
// sdk stuff
import io/File
import os/[Process, Pipe, ShellUtils]
import structs/[List, ArrayList]

// our stuff
import Flags
import rock/frontend/BuildParams
import rock/middle/Module

/**
 * This classes handles the launch of our C compiler and linker.
 * Usually that'll be 'gcc' and 'gcc', or 'clang' and 'clang',
 * but it could well be 'gcc' and 'g++', if you're linking with C++
 * code (god forbid).
 */
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
            executablePath = execFile getName()
        } else {
            // If we initially got an existing compiler path, just use this one.
            executablePath = execFile getAbsolutePath()
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
        parent := File new(flags outPath) parent
        if(!parent exists?()) {
            if(params verbose) "Creating path %s" format(parent getPath()) println()
            parent mkdirs()
        }

        process := Process new(command)

        // display the command line if needed
        if (params verbose) {
            if (params verboser) {
                process getCommandLine() println()
            } else {
                action := match link {
                    case true => "[LD]"
                    case =>      "[CC]"
                }
                target := match link {
                    case true => flags outPath
                    case      =>
                        match (flags mainModule) {
                            case null =>
                                flags objects join(" ")
                            case =>
                                flags mainModule fullName
                        }
                }

                "%s %s" printfln(action, target)
            }
        }
        // process setStderr(Pipe new())

        // actually launch the command
        process executeNoWait()
        process
    }
}
