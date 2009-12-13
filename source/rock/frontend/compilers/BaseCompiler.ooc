import io/File
import structs/[List, ArrayList]
import text/StringBuffer
import os/Process

import AbstractCompiler
import ../../utils/ShellUtils

BaseCompiler: abstract class extends AbstractCompiler {
    
    command: List<String>
    executablePath: String
    
    init: func(executableName: String) {
        
        command = ArrayList<String> new();
        executablePath = ""
        
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
        reset()
    }
    
    launch: func() -> Int {
        proc := Process new(command) 
        return proc execute()
    }
    
    reset: func() {
        command clear();
        command add(executablePath);
    }
    
    getCommandLine: func() -> String {
        commandLine := StringBuffer new()
                
        for(arg: String in command) {
            commandLine append(arg)
            commandLine append(" ")
        }
                        
        return commandLine toString()
    }
}