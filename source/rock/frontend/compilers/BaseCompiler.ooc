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
		
		execFile := File new(executableName)
		
		if (!execFile exists()) {
			execFile = ShellUtils findExecutable(executableName, false)
			if (execFile == null) {
				ShellUtils findExecutable(executableName + "exe", false)
				if (execFile == null) {
					ShellUtils findExecutable(executableName + "exe", true)
				}
			}
		}
		
		executablePath = execFile name()
		reset()
	}
	
	launch: func() -> Int {
		proc := SubProcess new((command as ArrayList) data) 
		return proc execute()
	}
	
	reset: func() {
		command clear();
		command add(executablePath);
	}
	
	getCommandLine: func() -> String {
		commandLine := StringBuffer new()
				
		for(arg in command) {
			commandLine append(arg);
			commandLine append(' ');
		}
		
		return commandLine toString()
	}
	
}