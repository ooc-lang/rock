import ../utils/ShellUtils
import io/[File]
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
            //return File new(File new(realpath) parent() parent() parent() path, "ooc")
            return File new(File new(realpath) parent())
        }
        
        // fall back on the current working directory
        file := File new(File getCwd())
        return file parent()
    }
    
}