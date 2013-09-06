import io/File
import os/Env
import text/StringTokenizer


/**
 * Utilities for launching processes
 */
ShellUtils: class {

    /**
     * @return the path of an executable, if it can be found. It looks in the PATH
     * environment variable.
     */
    findExecutable: static func (executableName: String, crucial := false) -> File {
        file: File

        version (windows) {
            file = _findInPath("%s.exe" format(executableName))
            if (file) return file
        }

        file = _findInPath(executableName)
        if (file) return file

        if (crucial) {
            Exception new("Command not found: " + executableName) throw()
        }

        null
    }

    _findInPath: static func (executableName: String) -> File {
        simple := File new(executableName)
        if(simple exists?() && simple file?()) {
            return simple
        }

        pathVar := Env get("PATH")
        if (pathVar == null) {
            pathVar = Env get("Path")
            if (pathVar == null) {
                pathVar = Env get("path")
            }
        }

        if (pathVar == null) {
            "PATH environment variable not found!" println()
            return null
        }

        st := pathVar split(File pathDelimiter)
        for(foo in st) {
            path := foo + File separator + executableName
            file := File new(path)
            if (file exists?()) {
                return file
            }
        }

        null
    }

}
