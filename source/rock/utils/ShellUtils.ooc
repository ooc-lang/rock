import io/File
import os/Env
import text/StringTokenizer


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
    findExecutable: static func (executableName: String, crucial: Bool) -> File {

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

        st := StringTokenizer new(pathVar, File pathDelimiter)
        while (st hasNext()) {
            path := st nextToken() + File separator + executableName
            file := File new(path)
            if (file exists()) {
                return file
            }
        }

        if(crucial) {
            Exception new("Couldn't find " + executableName + " on your system. PATH = " + pathVar) throw()
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