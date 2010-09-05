import io/File
import structs/ArrayList
import text/[StringTokenizer]

/**
 * A collection of file utilities that should have been in the
 * Java SDK.
 *
 * @author Amos Wenger
 */
FileUtils: class {
    /**
     * Resolve redundancies, ie. ".." and "."
     * @param file
     * @return cleaned up file
     */
    resolveRedundancies: static func(path: String) -> String {
        elems := ArrayList<String> new()

        for (elem in path split(File separator)) {
            if (elem == "..") {
                if (!elems empty?()) {
                    elems removeAt(elems lastIndex())
                } else {
                    elems add(elem)
                }
            } else if (elem == ".") {
                // do nothing
            } else {
                elems add(elem)
            }
        }

        mysize := elems getSize()
        
        buffer := Buffer new(path size + mysize + 1)
        if (path startsWith?(File separator)) {
            buffer append(File separator)
        }        
        
        count := 0
        for (elem in elems) {
            buffer append(elem)
            count += 1
            if (count < mysize) {
                buffer append(File separator)
            }
        }
        return buffer toString()
    }
}
