import io/File
import os/Env

import DistLocator

SdkLocator: class {
    
    locate: static func -> File {
        envDist := Env get("OOC_SDK")
        if (envDist != null) {
            return File new(envDist)
        }
        
        //return File new(DistLocator locate() getPath() + File separator + "sdk")
        return File new(DistLocator locate() getPath() + File separator + "custom-sdk")
    }
    
}