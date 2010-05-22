import ../utils/ShellUtils
import io/[File]
import os/Env
import rock/rock

DistLocator: class {
    
    locate: static func -> File {
        rockDist := Env get("ROCK_DIST")
        if (rockDist != null) {
            return File new(rockDist trimRight(File separator))
        }
        
        oocDist := Env get("OOC_DIST")
        if (oocDist != null) {
            return File new(oocDist trimRight(File separator))
        }
    
        exec := ShellUtils findExecutable(Rock execName, false)
        if(exec) {
            realpath := exec getAbsolutePath()
            return File new(realpath) parent() parent()
        }
        
        // fall back on the current working directory
        file := File new(File getCwd())
        return file parent()
    }
    
}