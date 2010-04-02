import io/File
import os/Env

import DistLocator, ../utils/ShellUtils, rock/rock

SdkLocator: class {
    
    locate: static func -> File {
        rockSdk := Env get("ROCK_SDK")
        if (rockSdk != null) {
            return File new(rockSdk)
        }
        
        oocSdk := Env get("OOC_SDK")
        if (oocSdk != null) {
            return File new(oocSdk)
        }
        
        exec := ShellUtils findExecutable(Rock execName, false)
        if(exec) {
            realpath := exec getAbsolutePath()
            return File new(File new(realpath) parent() parent(), "custom-sdk/")
        }
        
        return File new(DistLocator locate(), "custom-sdk")
    }
    
}