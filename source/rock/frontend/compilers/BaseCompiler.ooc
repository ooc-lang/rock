import io/File
import structs/[List, ArrayList]
import text/Buffer
import os/Process

import AbstractCompiler
import ../../utils/ShellUtils

BaseCompiler: abstract class extends AbstractCompiler {
    
    command: List<String>
    executablePath: String
    
    init: func(executableName: String) {
        command = ArrayList<String> new();
        executablePath = ""
        
        setExecutable(executableName)
    }
    
    setExecutable: func (executableName: String) {
        execFile := File new(executableName)
        
        if (!execFile exists()) {
            execFile = ShellUtils findExecutable(executableName, false)
            if (execFile == null) {
                execFile = ShellUtils findExecutable(executableName + ".exe", false)
                if (execFile == null) {
                    execFile = ShellUtils findExecutable(executableName, true)
                }
            }
        }
        
        executablePath = execFile name()
        if(command isEmpty()) {
            command add(executablePath)
        } else {
            command set(0, executablePath)
        }
    }
    
    launch: func() -> Int {
        proc := Process new(command) 
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