import io/File
import os/Env

DistLocator: class {
	locate: static func -> File {
		envDist := Env get("OOC_DIST")
		if (envDist != null) {
			return File new(envDist)
		}
		
		return null;
	}
}