import io/File

getenv: extern func(path: String) -> String

/**
 * Utilities for launching processes
 *  
 * @author Amos Wenger
 */
ShellUtils: class {
	
	/**
	 * @return the path of an executable, if it can be found. It looks in the PATH
	 * environment variable.
	 */
	findExecutable: static func (exectuableName: String, crucial: Bool) -> File {
		
		pathVar := getenv("PATH")
		if (pathVar == null) {
			pathVar = getenv("Path") 
			if (pathVar == null) {
				pathVar = getenv("path")
			}
		}
		
		if (pathVar == null) {
			"PATH environment variable not found!" println()
			return null
		}

			// TODO: implement StringTokenizer, actually find the file
			/*StringTokenizer st = new StringTokenizer(pathVar, File.pathSeparator);
			while(st.hasMoreTokens()) {
				String path = st.nextToken();
				File file = new File(path, executableName);
				if(file.exists() && file.isFile()) {
					return file;
				}
			}*/

		if(crucial) {
			Exception new("Couldn't find " + exectuableName + " on your system. PATH = " + pathVar) throw()
		}
		
		return null;
	}
	
	/**
	 * Run a command to get its output
	 * @param command
	 * @return the output of the command specified, once it has exited
	 */
	getOuput: static func(command: String) -> String {
		// TODO fill in
		return null
	}

}