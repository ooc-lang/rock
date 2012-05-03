include stdio

import structs/ArrayList
import FileReader, FileWriter, Reader, BufferWriter, BufferReader
import native/[FileWin32, FileUnix]
import text/StringTokenizer

/**
   Represents a file/directory path, allows to retrieve informations like
   last date of creation/access/modification, permissions, size,
   existence, content, type, children...

   You can also create directories, remove files, read their content,
   copy them, write to them.

   For input/output (I/O) beyond 'reading to a String' and
   'writing a String', see the FileReader and FileWriter classes

   @author Pierre-Alexandre Croiset
   @author Friedrich Weber (fredreichbier)
   @author Amos Wenger (nddrylliog)
 */
File: abstract class {

    /** The path we're representing */
    path: String { get set }
    
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
       Create a File object from the given path
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
       Create a File object, relative to the given parent file
     */
    new: static func ~parentFile (parent: File, .path) -> This {
        assert(parent != null)
        assert(parent path != null)
        assert(!parent path empty?())
        new(parent path + This separator + path)
    }

    /**
       Create a File object, relative to the given parent path
     */
    new: static func ~parentPath (parent: String, .path) -> This {
        return new(parent + This separator + path)
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
     * @return true if the file exists and can be
     * opened for reading
     */
    exists?: func -> Bool {
        fd := FStream open(path, "rb")
        if(fd) {
            fd close()
            return true
        }
        false
    }

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
     * @return the last part of the path, e.g. for /etc/init.d/bluetooth
     * name() will return 'bluetooth'
     */
    name: func -> String {
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
    parent: func -> File {
        pName := parentName()
        if (pName) return File new(pName)
        if (path != "." && !path startsWith?(This separator)) return File new(".") // return the current directory
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
     * create a named pipe at the path specified by this file,
     * with permissions 0c755 by default
     */
    mkfifo: func -> Int {
        mkfifo(0c755)
    }

    /**
     * create a directory at the path specified by this file
     *
     * :param mode: The permissions at the creation of the directory
     */
    mkfifo: abstract func ~withMode (mode: Int32) -> Int

    /**
     * create a directory at the path specified by this file,
     * with permissions 0c755 by default
     */
    mkdir: func -> Int {
        mkdir(0c755)
    }

    /**
     * create a directory at the path specified by this file
     *
     * :param mode: The permissions at the creation of the directory
     */
    mkdir: abstract func ~withMode (mode: Int32) -> Int

    /**
     * create a directory at the path specified by this file,
     * and all the parent directories if needed,
     * with permissions 0c755 by default
     */
    mkdirs: func {
        mkdirs(0c755)
    }

    /**
     * create a directory at the path specified by this file,
     * and all the parent directories if needed
     *
     * :param mode: The permissions at the creation of the directory
     */
    mkdirs: func ~withMode (mode: Int32) -> Int {
        if (parent := parent()) {
            parent mkdirs()
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
     * the path this file has been created with
     */
    getPath: func -> String { path }

    /**
     * The absolute path, e.g. "my/dir" => "/current/directory/my/dir"
     */
    getAbsolutePath: abstract func -> String

    /**
     * A file corresponding to the absolute path
     *
     * :see: getAbsolutePath
     */
    getAbsoluteFile: func -> This {
        return File new(getAbsolutePath())
    }

    /**
     * Resolve redundancies, ie. ".." and "."
     */
    getReducedPath: func -> String {
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

        result := elems join(File separator)
        if (path startsWith?(File separator)) {
            result = File separator + result
        }        

        result
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
     * Tries to remove the file. This only works for files, not directories.
     */
    remove: func -> Int {
        _remove(this path)
    }

    /**
     * Copies the content of this file to another
     *
     * :param dstFile: the file to copy to
     */
    copyTo: func(dstFile: This) {
        dstFile parent() mkdirs()

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
       @return The content of this file, as a String
     */
    read: func -> String {
        fR := FileReader new(this)
        bW := BufferWriter new() .write(fR) .close()
        fR close()
        bW buffer toString()
    }

    /**
       Write a string to this file.

       @param str The string to write
     */
    write: func ~string (str: String) {
        FileWriter new(this) write(BufferReader new(str _buffer)) .close()
    }

    /**
       Write from a reader to this file

       @param reader What to write in the file
     */
    write: func ~reader (reader: Reader) {
        FileWriter new(this) write(reader) . close()
    }

    /**
       Walk this directory and call `f` on all files it contains, recursively.

       If `f` returns false, stop walking.

       If we're not a directory, calls f(this) once and returns true.

       @return true if we finished walking normally, false if we
       got cancelled by `f` returning false.
     */
    walk: func (f: Func(File) -> Bool) -> Bool {
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
       Get a child of this path

       @param name The name of the child, relatively to this path
     */
    getChild: func (name: String) -> This {
        new(this path + This separator + name)
    }

    /**
       @return the current working directory
     */
    getCwd: static func -> String {
        ooc_get_cwd()
    }

}

_isDirHardlink?: inline func (dir: CString) -> Bool {
    (dir[0] == '.') && (dir[1] == '\0' || ( dir[1] == '.' && dir[2] == '\0'))
}

