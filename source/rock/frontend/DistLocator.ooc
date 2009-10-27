import io/[Directory, File]
import os/Env

DistLocator: class {
    
	locate: static func -> File {
		envDist := Env get("OOC_DIST")
		if (envDist != null) {
			return File new(envDist)
		}
		
		// fall back on the current working directory
		file := File new(Directory getCwd())
		return file parent()
	}
    
}