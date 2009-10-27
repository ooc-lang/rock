import ../utils/ShellUtils
import io/[Directory, File]
import os/Env
import rock/rock

DistLocator: class {
    
	locate: static func -> File {
		envDist := Env get("OOC_DIST")
		if (envDist != null) {
			return File new(envDist)
		}
	
        exec := ShellUtils findExecutable(Rock execName, false)
        if(exec) {
            realpath := exec getAbsolutePath()
            return File new(File new(realpath) parent() parent() parent() path, "ooc")
        }
    	
		// fall back on the current working directory
		file := File new(Directory getCwd())
		return file parent()
	}
    
}