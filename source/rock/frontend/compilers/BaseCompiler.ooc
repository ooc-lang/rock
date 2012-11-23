import io/File
import os/[Process,Pipe]

import AbstractCompiler
import ../../utils/ShellUtils

BaseCompiler: abstract class extends AbstractCompiler {

    init: func ~baseCompiler (.executableName) {
        setExecutable(executableName)
    }

    setExecutable: func (=executableName) {
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

        if(command empty?()) {
            command add(executablePath)
        } else {
            command set(0, executablePath)
        }
    }

    launch: func() -> Int {
        proc := Process new(command)
        
        if(silence) proc setStderr(Pipe new())
        
        return proc execute()
    }

    reset: func() {
        command clear()
        command add(executablePath)
    }

    getCommandLine: func() -> String {
        commandLine := Buffer new()

        for(arg: String in command) {
            commandLine append(arg)
            commandLine append(" ")
        }

        return commandLine toString()
    }
}
