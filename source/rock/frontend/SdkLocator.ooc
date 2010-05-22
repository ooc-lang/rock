import io/File
import os/Env

import DistLocator, ../utils/ShellUtils, rock/rock

SdkLocator: class {
    
    locate: static func -> File {
        rockSdk := Env get("ROCK_SDK")
        if (rockSdk != null) {
            return File new(rockSdk trimRight(File separator))
        }
        
        oocSdk := Env get("OOC_SDK")
        if (oocSdk != null) {
            return File new(oocSdk trimRight(File separator))
        }
        
        exec := ShellUtils findExecutable(Rock execName, false)
        if(exec) {
            realpath := exec getAbsolutePath()
            return File new(File new(realpath) parent() parent(), "sdk")
        }
        
        return File new(DistLocator locate(), "sdk")
    }
    
}