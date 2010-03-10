/**
 * Allows to test various file attributes, list the children
 * of a directory, etc.
 *
 * :author: Pierre-Alexandre Croiset
 * :author: fredreichbier
 * :author: Amos Wenger, aka nddrylliog
 */

// the pipe (e.g. '|') and __USE_BSD are used like #define
// before includes. In this case, we need __USE_BSD to get lstat()

include stdio

import structs/ArrayList
import FileReader, FileWriter
import native/[FileWin32, FileUnix]

File: abstract class {

    MAX_PATH_LENGTH := static const 16383 // cause we alloc +1

    path: String

    // overriden in FileWin32 & friends
    separator = '/' : static Char
    pathDelimiter = ':' : static Char

    getPath: func -> String {
        return path
    }

    new: static func (.path) -> This {
        version(unix || apple) {
            return FileUnix new(path)
        }
        version(windows) {
            return FileWin32 new(path)
        }
        Exception new(This, "Unsupported platform!\n") throw()
        null
    }

    new: static func ~parentFile(parent: File, .path) -> This {
        return new(parent path + This separator + path)
    }

    new: static func ~parentPath(parent: String, .path) -> This {
        return new(parent + This separator + path)
    }

    /**
     * :return: true if it's a directory
     */
    isDir: abstract func -> Bool

    /**
     * :return: true if it's a file (ie. not a directory nor a symbolic link)
     */
    isFile: abstract func -> Bool

    /**
     * :return: true if the file is a symbolic link
     */
    isLink: abstract func -> Bool

    /**
     * :return: the size of the file, in bytes
     */
    size: abstract func -> LLong

    /**
     * :return: true if the file exists and can be
     * opened for reading
     */
    exists: func -> Bool {
        fd := fopen(path, "r")
        if(fd) {
            fclose(fd); return true
        }
        false
    }

    /**
     * :return: the permissions for the owner of this file
     */
    ownerPerm: abstract func -> Int

    /**
     * :return: the permissions for the group of this file
     */
    groupPerm: abstract func -> Int

    /**
     * :return: the permissions for the others (not owner, not group)
     */
    otherPerm: abstract func -> Int

    /**
     * :return: the last part of the path, e.g. for /etc/init.d/bluetooth
     * name() will return 'bluetooth'
     */
    name: func -> String {
        trimmed := path trim(This separator)
        idx := trimmed lastIndexOf(This separator)
        if(idx == -1) return trimmed
        return trimmed substring(idx + 1)
    }

    /**
     * :return: the parent of this file, e.g. for /etc/init.d/bluetooth
     * it will return /etc/init.d/ (as a File), or null if it's the
     * root directory.
     */
    parent: func -> File {
        pName := parentName()
        if(pName) return File new(pName)
        return null
    }

    /**
     * :return: the parent of this file, e.g. for /etc/init.d/bluetooth
     * it will return /etc/init.d/ (as a File), or null if it's the
     * root directory.
     */
    parentName: func -> String {
        idx := path lastIndexOf(This separator)
        if(idx == -1) return null
        return path substring(0, idx)
    }

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
        if(parent := parent()) {
            parent mkdirs()
        }
        mkdir()
    }

    /**
     * :return: the time of last access
     */
    lastAccessed: abstract func -> Long

    /**
     * :return: the time of last modification
     */
    lastModified: abstract func -> Long

    /**
     * :return: the time of creation
     */
    created: abstract func -> Long

    /**
     * :return: true if the function is relative to the current directory
     */
    isRelative: abstract func -> Bool

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
        buffer : Char[max]
        while(src hasNext()) {
            num := src read(buffer, 0, max)
            dst write(buffer, num)
        }
        dst close()
        src close()
    }

    /**
     * Get a child of this path
     *
     * :param name: The name of the child, relatively to this path
     */
    getChild: func (name: String) -> This {
        new(this path + This separator + name)
    }

    /**
     * :return: the current working directory
     */
    getCwd: static func -> String {
        ret := String new(File MAX_PATH_LENGTH + 1)
        _getcwd(ret, File MAX_PATH_LENGTH)
        return ret
    }

}
