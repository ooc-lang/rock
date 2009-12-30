import io/File
import os/Env

import DistLocator, ../utils/ShellUtils, rock/rock

SdkLocator: class {
    
    locate: static func -> File {
        exec := ShellUtils findExecutable(Rock execName, false)
        if(exec) {
            realpath := exec getAbsolutePath()
            println("absolute path to rock = " + realpath)
            return File new(File new(realpath) parent() parent() path, "custom-sdk/")
        }
        
        envDist := Env get("OOC_SDK")
        if (envDist != null) {
            return File new(envDist)
        }
        
        //return File new(DistLocator locate() getPath() + File separator + "sdk")
        return File new(DistLocator locate() getPath() + File separator + "custom-sdk")
    }
    
}