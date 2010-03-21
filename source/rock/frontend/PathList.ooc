import io/[File]
import structs/[ArrayList, List, HashMap]

/**
 * Somehow like the 'classpath' in Java. E.g. holds where to find ooc
 * modules, and well, find them when asked kindly to.
 *
 * @author Amos Wenger
 */
PathList: class {
    paths := HashMap<String, File> new()

    getPaths : func -> HashMap<String, File> { paths }

    /**
     * Add an element to the classpath
     * @param path
     */
    add: func(path: String) {
        file := File new(path)

        if (!file exists()) {
            Exception new(This, "Classpath element cannot be found: %s" format(path)) throw()
        }
        else if (!file isDir()) {
            Exception new(This, "Classpath element is not a directory: %s" format(path)) throw()
        }

        absolutePath := file getAbsolutePath()
        if (!paths contains(absolutePath)) {
            paths put(absolutePath, file)
        }
    }

    /**
     * Remove an element from the sourcepath
     * @param path
     */
    remove: func(path: String) {
        file := File new(path)

        if (!file exists()) {
            Exception new(This, "Classpath element cannot be found: " + file getPath()) throw()
        }
        else if (!file isDir()) {
            Exception new(This, "Classpath element is not a directory: " + file getPath()) throw()
        }
        else if (!paths contains(file getAbsolutePath())) {
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
     * @param path
     * @return
     */
    getRelativePaths: func(path: String) -> List<String> {
        files := ArrayList<String> new()

        for (element: File in paths) {
            //printf("Looking for path %s in element %s\n", path, element path)
            candidate := File new((element path + File separator) + path)
            //printf("Candidate = %s\n", candidate path)
            if (candidate exists() && candidate isDir()) {
                addChildren(path, files, candidate);
            }
        }

        return files
    }

    addChildren: func(basePath: String, list: List<String>, parent: File) {

        for (child: File in parent getChildren()) {
            if (child isFile()) {
                list add(basePath + File separator + child name())
            }
            else if (child isDir()) {
                addChildren(basePath + File separator + child name(), list, child)
            }
        }
    }

    /**
     * Find the file in the source path and return a File object associated to it
     */
    getFile: func(path: String) -> File {
        element := getElement(path)
        return element == null ? null : File new(element getPath() + File separator + path)
    }


    /**
     * Find the file in the source path and return the element of the path list
     * it has been found in.
     */
    getElement: func(path: String) -> File {
        for (element: File in paths) {
            candidate := File new(element getPath() + File separator + path)
            if (candidate exists()) {
                return element
            }
        }

        return null
    }

    /**
     * @return true if the source path is empty
     */
    isEmpty: func -> Bool {
        return paths isEmpty()
    }
    
}


