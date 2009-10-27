import io/File

getenv: extern func(path: String) -> String

DistLocator: class {
	locate: static func -> File {
		envDist := getenv("OOC_DIST")
		if (envDist != null) {
			return File new(envDist)
		}
		
		return null;
	}
}