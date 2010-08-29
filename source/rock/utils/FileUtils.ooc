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
        //("resolveRedundancies called on " + path) println()
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

        buffer := Buffer new(path length())
        if (path startsWith?(File separator)) {
            buffer append(File separator)
        }

        size := elems size()
        count := 0
        for (elem in elems) {
            buffer append(elem)
            count += 1
            if (count < size) {
                buffer append(File separator)
            }
        }

        return buffer toString()
    }
}
