
import io/[File]
import structs/[ArrayList, List, HashMap]
import rock/frontend/[CommandLine, BuildParams]

/**
 * Somehow like the 'classpath' in Java. E.g. holds where to find ooc
 * modules, and well, find them when asked kindly to.
 */
PathList: class {
    paths := HashMap<String, File> new()
    debug := false

    getPaths : func -> HashMap<String, File> { paths }

    init: func

    /**
     * Add an element to the classpath
     * :param: path
     */
    add: func (path: String) {
        file := File new(path)

        if (!file exists?()) {
            Exception new(This, "Classpath element cannot be found: %s" format(path)) throw()
        }
        else if (!file dir?()) {
            Exception new(This, "Classpath element is not a directory: %s" format(path)) throw()
        }

        absolutePath := file getAbsolutePath()
        if (!paths contains?(absolutePath)) {
            paths put(absolutePath, file)
        }
    }

    /**
     * Get an element from the classpath, from its folder name
     */
    get: func (folderName: String) -> File {
        for (path in paths) {
            if (path getAbsoluteFile() name == folderName) return path
        }
        null
    }

    /**
     * Remove an element from the sourcepath
     * :param: path
     */
    remove: func(path: String) {
        file := File new(path)

        if (!file exists?()) {
            Exception new(This, "Classpath element cannot be found: " + file getPath()) throw()
        }
        else if (!file dir?()) {
            Exception new(This, "Classpath element is not a directory: " + file getPath()) throw()
        }
        else if (!paths contains?(file getAbsolutePath())) {
            Exception new(This, "Attempting to remove a nonexistant path: " + file getPath()) throw()
        }

        paths remove(file getAbsolutePath())
    }

    /**
     * Remove all elements from the sourcepath
     */
    clear: func {
        paths clear()
    }

    /**
     * Return a list of all files found in a directory in the whole sourcepath
     * :param: path
     * @return
     */
    getRelativePaths: func(path: String) -> List<String> {
        files := ArrayList<String> new()
        for (element: File in paths) {
            candidate := File new((element path + File separator) + path)
            if (candidate exists?() && candidate dir?()) {
                addChildren(path, files, candidate)
            }
        }
        return files
    }

    addChildren: func(basePath: String, list: List<String>, parent: File) {
        for (child in parent getChildren()) {
            if (child file?()) {
                list add(basePath + File separator + child name)
            } else if (child dir?()) {
                addChildren(basePath + File separator + child name, list, child)
            }
        }
    }

    /**
     * Find the file in the source path and return
     *   - a File object associated to it
     *   - the element of the path list it's been found in
     */
    getFile: func (path: String) -> (File, File) {
        for(element in paths) {
            candidate := File new(element path, path)
            if (candidate exists?() && candidate file?()) {
                if(debug) ("For " + path + ", found path " + candidate getPath() + " in element " + element getPath()) println()
                return (candidate, element)
            }
        }
        (null, null)
    }

    /**
     * Find the file in the given path element of the source path.
     * @see getFile
     */
    getFileInElement: func (path, elementPath: String, params: BuildParams) -> (File, File) {
        element := File new(elementPath)
        reducedElement := element getReducedPath()
        candidate := File new(element, path)
        if (candidate exists?() && candidate file?()) {
            reduced := candidate getReducedPath()
            valid := reduced startsWith?(reducedElement)
            if (!valid) {
                // can't escape the sourcepath!
                CommandLine error("Import %s was found at %s, but it can't escape source element %s" format(path, reduced, reducedElement))
                CommandLine failure(params)
            }
            return (candidate, element)
        }
        (null, null)
    }

    /**
     * @return true if the source path is empty
     */
    empty?: func -> Bool {
        return paths empty?()
    }

    toString: func -> String {
        buffer := Buffer new()

        first := true
        for (element in paths) {
            if (first) { first = false } else { buffer append(", ") }
            buffer append(element path)
        }

        buffer toString()
    }

}


