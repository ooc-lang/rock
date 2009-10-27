import io/File

import DistLocator

getenv: extern func(path: String) -> String

SdkLocator: class {
	locate: static func -> File {
		envDist := getenv("OOC_SDK")
		if (envDist != null) {
			return File new(envDist)
		}
		
		return File new(DistLocator locate() getPath() + File separator + "sdk")
	}
}