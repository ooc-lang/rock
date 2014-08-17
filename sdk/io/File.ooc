include stdio

import structs/ArrayList
import FileReader, FileWriter, Reader, BufferWriter, BufferReader
import native/[FileWin32, FileUnix]
import text/StringTokenizer

/**
 * Represents a file/directory path, allows to retrieve informations like
 * last date of creation/access/modification, permissions, size,
 * existence, content, type, children...
 *
 * You can also create directories, remove files, read their content,
 * copy them, write to them.
 *
 * For input/output (I/O) beyond 'reading to a String' and
 * 'writing a String', see the FileReader and FileWriter classes
 */
File: abstract class {

    /** The path we're representing */
    path: String { get set }

    name: String { get { getName() } }
    parent: This { get { getParent() } }

    children: ArrayList<This> {
        get {
            getChildren()
        }
    }

    /** Separator for path elements. Usually '/' on *nix and '\\' on Windows. */
    separator: static Char

    /** Delimiter for lists of paths. Usually ':' on *nix and ';' on Windows. */
    pathDelimiter: static Char

    /**
     * Maximum path length used to retrieve the current working directory (cwd)
     * We use our own constant
     */
    MAX_PATH_LENGTH := static const 16383 // cause we alloc +1

    /**
     * Create a File object from the given path
     */
    new: static func (.path) -> This {
        version (unix || apple) {
            return FileUnix new(path)
        }
        version (windows) {
            return FileWin32 new(path)
        }
        Exception new(This, "Unsupported platform!\n") throw()
        null
    }

    /**
     * Create a File object, from various path elements,
     * which can be either File instances or Strings.
     */
    new: static func ~assemble (args: ...) -> This {
        This new(This join(args))
    }

    /**
     * @return true if it's a directory
     */
    dir?: abstract func -> Bool

    /**
     * @return true if it's a file (ie. not a directory nor a symbolic link)
     */
    file?: abstract func -> Bool

    /**
     * @return true if the file is a symbolic link
     */
    link?: abstract func -> Bool

    /**
     * @return the size of the file, in bytes
     */
    getSize: abstract func -> LLong

    /**
     * @return true if the file exists
     */
    exists?: abstract func -> Bool

    /**
     * @return the permissions for the owner of this file
     */
    ownerPerm: abstract func -> Int

    /**
     * @return the permissions for the group of this file
     */
    groupPerm: abstract func -> Int

    /**
     * @return the permissions for the others (not owner, not group)
     */
    otherPerm: abstract func -> Int
    
    /**
     * @return true if a file is executable by the current owner
     */
    executable?: abstract func -> Bool

    /**
     * set the executable bit on this file's permissions for
     * current user, group, and other.
     */
    setExecutable: abstract func (exec: Bool) -> Bool

    /**
     * @return the path of the file represented by this instance
     */
    getPath: func -> String {
        path
    }

    /**
     * @return the last part of the path, e.g. for /etc/init.d/bluetooth
     * name() will return 'bluetooth'
     */
    getName: func -> String {
        trimmed := path trim(This separator)
        idx := trimmed lastIndexOf(This separator)
        if (idx == -1) return trimmed
        return trimmed substring(idx + 1)
    }

    /**
     * @return the parent of this file, e.g. for /etc/init.d/bluetooth
     * it will return /etc/init.d/ (as a File), or null if it's the
     * root directory.
     */
    getParent: func -> This {
        pName := parentName()
        if (pName) return new(pName)
        if (path != "." && !path startsWith?(This separator)) return new(".") // return the current directory
        return null
    }

    /**
     * @return the parent of this file, e.g. for /etc/init.d/bluetooth
     * it will return /etc/init.d/ (as a File), or null if it's the
     * root directory.
     */
    parentName: func -> String {
        idx := path lastIndexOf(This separator)
        if (idx == -1) return null
        return path substring(0, idx)
    }

    /**
     * Create a named pipe at the path specified by this file,
     * with permissions 0c755 by default
     */
    mkfifo: func -> Int {
        mkfifo(0c755)
    }

    /**
     * Create a directory at the path specified by this file
     *
     * @param mode The permissions at the creation of the directory
     */
    mkfifo: abstract func ~withMode (mode: Int32) -> Int

    /**
     * Create a directory at the path specified by this file,
     * with permissions 0c755 by default
     */
    mkdir: func -> Int {
        mkdir(0c755)
    }

    /**
     * Create a directory at the path specified by this file
     *
     * @param mode The permissions at the creation of the directory
     */
    mkdir: abstract func ~withMode (mode: Int32) -> Int

    /**
     * Create a directory at the path specified by this file,
     * and all the parent directories if needed,
     * with permissions 0c755 by default
     */
    mkdirs: func {
        mkdirs(0c755)
    }

    /**
     * Create a directory at the path specified by this file,
     * and all the parent directories if needed
     *
     * @param mode The permissions at the creation of the directory
     */
    mkdirs: func ~withMode (mode: Int32) -> Int {
        p := parent
        if (p) {
            p mkdirs(mode)
        }
        mkdir()
    }

    /**
     * @return the time of last access
     */
    lastAccessed: abstract func -> Long

    /**
     * @return the time of last modification
     */
    lastModified: abstract func -> Long

    /**
     * @return the time of creation
     */
    created: abstract func -> Long

    /**
     * @return true if the function is relative to the current directory
     */
    relative?: abstract func -> Bool

    /**
     * The absolute path, e.g. "my/dir" => "/current/directory/my/dir"
     */
    getAbsolutePath: abstract func -> String

    /**
     * The long path, normalize casing on case-insensitive filesystems
     * like Win32.
     * On case-sensitive filesystems, returns the same path.
     */
    getLongPath: func -> String { path }

    /**
     * A file corresponding to the absolute path
     *
     * @see getAbsolutePath
     */
    getAbsoluteFile: func -> This {
        new(getAbsolutePath())
    }

    /**
     * Resolve redundancies, ie. ".." and "."
     */
    getReducedPath: func -> String {
        elems := ArrayList<String> new()

        tokens := path split(This separator)
        for (elem in tokens) {
            if (elem == "..") {
                if (!elems empty?()) {
                    elems removeAt(elems lastIndex())
                } else {
                    elems add(elem)
                }
            } else if (elem == "." || elem == "") {
                // do nothing
            } else {
                elems add(elem)
            }
        }

        result := elems join(This separator)
        if (path startsWith?(This separator)) {
            result = This separator + result
        }

        result
    }

    /**
     * @return a new File with resolved redundancies
     */
    getReducedFile: func -> This {
        new(getReducedPath())
    }

    /**
     * List the name of the children of this path
     * Works only on directories, obviously
     */
    getChildrenNames: abstract func -> ArrayList<String>

    /**
     * List the children of this path
     * Works only on directories, obviously
     */
    getChildren: abstract func -> ArrayList<This>

    /**
     * Tries to remove the file. This only works for files or empty directories
     * @return true if successful
     */
    rm: func -> Bool {
        _remove(this)
    }

    /**
     * Delete a file or directory and all its children, recursively
     */
    rm_rf: func -> Bool {
        if (dir?()) {
            // delete em'all!
            for (child in getChildren()) {
                if (!child rm_rf()) {
                    return false
                }
            }
        }
        rm()
    }

    /**
     * Find a file or directory with the given name
     * @param name The name of the file to find (case sensitive)
     * @param cb A callback that takes a file whenever one is found.
     * if it returns false, the search will stop. If true, the search
     * will continue.
     * @return true if the file was found (cb returned false at some point),
     * or false if it wasn't.
     */
    find: func (name: String, cb: Func (File) -> Bool) -> Bool {

        if (getName() == name) {
            if (!cb(this)) {
                // abort if caller is happy
                return true
            }
        }

        if (dir?()) {
            children := getChildren()
            for (child in children) {
                if (child find(name, cb)) {
                    // abort if caller found happiness in a sub-directory
                    return true
                }
            }
        }

        false
    }

    /**
     * Find a file or directory with the given name
     * @return the first match for the given name
     */
    find: func ~first (name: String) -> This {
        result: This

        find(name, |f|
            result = f
            false
        )

        result
    }

    /**
     * Do a 'shallow search' for a file with a given
     * name.
     */
    findShallow: func (name: String, level: Int, cb: Func (File) -> Bool) -> Bool {
        fName := getName()
        if (fName == name) {
            if (!cb(this)) {
                // abort if caller is happy
                return true
            }
        }

        if (dir?() && level >= 0) {
            if (fName == ".git") {
                return false // skip
            }

            children := getChildren()
            for (child in children) {
                if (child findShallow(name, level - 1, cb)) {
                    // abort if caller found happiness in a sub-directory
                    return true
                }
            }
        }

        false

    }

    /**
     * Do a 'shallow search' for a file with a given
     * name.
     * @return the first match for the given name
     */
    findShallow: func ~first (name: String, level: Int) -> This {
        result: This

        findShallow(name, level, |f|
            result = f
            false
        )

        result
    }

    /**
     * Copies the content of this file to another
     *
     * @param dstFile the file to copy to
     */
    copyTo: func(dstFile: This) {
        dstFile parent mkdirs()

        src := FileReader new(this)
        dst := FileWriter new(dstFile)

        max := 8192
        buffer := Char[max] new()
        while (src hasNext?()) {
            num := src read(buffer data, 0, max)
            dst write(buffer data, num)
        }
        dst close()
        src close()
    }

    /**
     * @return The content of this file, as a String
     */
    read: func -> String {
        fR := FileReader new(this)
        bW := BufferWriter new() .write(fR) .close()
        fR close()
        bW buffer toString()
    }

    /**
     * Write a string to this file.
     *
     * @param str The string to write
     */
    write: func ~string (str: String) {
        FileWriter new(this) write(BufferReader new(str _buffer)) .close()
    }

    /**
     * Write from a reader to this file
     *
     * @param reader What to write in the file
     */
    write: func ~reader (reader: Reader) {
        FileWriter new(this) write(reader) . close()
    }

    /**
     * Walk this directory and call `f` on all files it contains, recursively.
     *
     * If `f` returns false, stop walking.
     *
     * If we're not a directory, calls f(this) once and returns true.
     *
     * @return true if we finished walking normally, false if we
     * got cancelled by `f` returning false.
     */
    walk: func (f: Func(This) -> Bool) -> Bool {
        if (file?()) {
            if (!f(this)) return false
        } else if (dir?()) {
            for (child in getChildren()) {
                if (!child walk(f)) return false
            }
        }

        true
    }

    /**
     * If this file has path:
     *
     * some/base/directory/sub/path
     *
     * And base is a file like:
     *
     * some/base/directory
     *
     * This method will return a File with path "sub/path"
     */
    rebase: func (base: File) -> This {
        left := base getReducedFile() getAbsolutePath() replaceAll(File separator, '/')
        full := getReducedFile() getAbsolutePath() replaceAll(File separator, '/')

        if (!left endsWith?("/")) {
            left = left + "/"
        }
        right := full substring(left size)
        File new(right)
    }

    /**
     * Get a child of this path
     *
     * @param childPath The name of the child, relatively to this path
     */
    getChild: func (childPath: String) -> This {
        new(this path, childPath)
    }

    /**
     * Get a child of this path
     *
     * @param file A child file - with a path relative to our own path
     */
    getChild: func ~file (file: This) -> This {
        getChild(file path)
    }

    /**
     * @return the current working directory
     */
    getCwd: static func -> String {
        ooc_get_cwd()
    }

    /**
     * Construct a path from any number of File(s) or String(s)
     */
    join: static func (args: ...) -> String {
        first := true

        result := Buffer new()

        args each(|arg|
            path := match arg {
                case f: File =>
                    f path
                case s: String =>
                    s
            }
            if (first) {
                first = false
            } else {
                result append(separator)
            }
            result append(path)
        )
        result toString()
    }

    toString: func -> String {
        "File(#{path})"
    }

}

_isDirHardlink?: inline func (dir: CString) -> Bool {
    (dir[0] == '.') && (dir[1] == '\0' || ( dir[1] == '.' && dir[2] == '\0'))
}

