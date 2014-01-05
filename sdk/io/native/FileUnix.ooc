import ../File, structs/ArrayList

include dirent

/*
 * Directory covers
 */

DIR: extern cover

DirEnt: cover from struct dirent {
    name: extern(d_name) CString
    /* TODO: the struct has more members, actually */
}

closedir: extern func (DIR*) -> Int
opendir: extern func (const CString) -> DIR*
readdir: extern func (DIR*) -> DirEnt*
readdir_r: extern func (DIR*, DirEnt*, DirEnt**) -> Int
rewinddir: extern func (DIR*)
seekdir: extern func (DIR*, Long)
telldir: extern func (DIR*) -> Long

realpath: extern func (path: CString, resolved: CString) -> CString

version (linux) {
    include unistd | (__USE_BSD), sys/stat | (__USE_BSD), sys/types | (__USE_BSD), stdlib | (__USE_BSD), limits
}
version (!linux) {
    include unistd, sys/stat, sys/types, stdlib
}

version (unix || apple) {

    // separators
    File separator = '/'
    File pathDelimiter = ':'

    _getcwd: extern(getcwd) func (buf: CString, size: SizeT) -> CString

    ooc_get_cwd: unmangled func -> String {
        result := Buffer new(File MAX_PATH_LENGTH)
        if (!_getcwd(result data as CString, File MAX_PATH_LENGTH)) {
            OSException new("error trying to getcwd! ") throw()
        }
        result sizeFromData()
        String new (result)
    }

    TimeT: cover from time_t
    ModeT: cover from mode_t

    FileStat: cover from struct stat {
        st_mode: extern ModeT
        st_size: extern SizeT
        st_atime, st_mtime, st_ctime: extern TimeT
    }

    // mode masks
    S_ISDIR: extern func (...) -> Bool // directory
    S_ISREG: extern func (...) -> Bool // regular
    S_ISLNK: extern func (...) -> Bool // symbolic link

    // permissions masks
    // Full, Read,    Write,   eXecute
    S_IRWXU, S_IRUSR, S_IWUSR, S_IXUSR: extern ModeT // user
    S_IRWXG, S_IRGRP, S_IWGRP, S_IXGRP: extern ModeT // group
    S_IRWXO, S_IROTH, S_IWOTH, S_IXOTH: extern ModeT // other

    lstat: extern func (CString, FileStat*) -> Int
    chmod: extern func (CString, ModeT) -> Int
    _mkdir: extern(mkdir) func (CString, ModeT) -> Int
    _mkfifo: extern(mkfifo) func (CString, ModeT) -> Int
    remove: extern func (path: CString) -> Int
    _remove: unmangled func (file: File) -> Bool {
        // returns 0 on success
        remove(file path) == 0
    }

    /*
     * Unix (POSIX) implementation of File
     */
    FileUnix: class extends File {

        init: func ~unix (=path)

        /**
         * @return true if it's a directory
         */
        dir?: func -> Bool {
            result: FileStat
            res := lstat(path as CString, result&)
            (res == 0 && S_ISDIR(result st_mode))
        }

        /**
         * @return true if it's a file (ie. not a directory nor a symbolic link)
         */
        file?: func -> Bool {
            result: FileStat
            res := lstat(path as CString, result&)
            (res == 0 && S_ISREG(result st_mode))
        }

        /**
         * @return true if the file is a symbolic link
         */
        link?: func -> Bool {
            result: FileStat
            res := lstat(path as CString, result&)
            (res == 0 && S_ISLNK(result st_mode))
        }

        /**
         * @return the size of the file, in bytes, or -1 if
         * the file doesn't exist.
         */
        getSize: func -> LLong {
            result: FileStat
            res := lstat(path as CString, result&)
            match res {
                case 0 => result st_size as LLong
                case => -1
            }
        }

        /**
         * @return true if the file exists
         */
        exists?: func -> Bool {
            result: FileStat
            res := lstat(path as CString, result&)
            (res == 0)
        }

        /**
         * @return the permissions for the owner of this file
         */
        ownerPerm: func -> Int {
            result: FileStat
            res := lstat(path as CString, result&)
            match res {
                case 0 => (result st_mode & S_IRWXU) as Int >> 6
                case => -1
            }
        }

        /**
         * @return the permissions for the group of this file
         */
        groupPerm: func -> Int {
            result: FileStat
            res := lstat(path as CString, result&)
            match res {
                case 0 => (result st_mode & S_IRWXG) as Int >> 3
                case => -1
            }
        }

        /**
         * @return the permissions for the others (not owner, not group)
         */
        otherPerm: func -> Int {
            result: FileStat
            res := lstat(path as CString, result&)
            match res {
                case 0 => (result st_mode & S_IRWXO) as Int
                case => -1
            }
        }

        /**
         * @return true if a file is executable by the current owner
         */
        executable?: func -> Bool {
            result: FileStat
            res := lstat(path as CString, result&)
            match res {
                case 0 => (result st_mode & S_IXUSR) != 0
                case => false
            }
        }

        /**
         * set the executable bit on this file's permissions for
         * current user, group, and other.
         */
       setExecutable: func (exec: Bool) -> Bool {
            result: FileStat
            res := lstat(path as CString, result&)
            if (res != 0) return false // couldn't get file mode

            mode := result st_mode
            if (exec) {
                mode |=  (S_IXUSR | S_IXGRP | S_IXOTH)
            } else {
                mode &= ~(S_IXUSR | S_IXGRP | S_IXOTH)
            }

            chmod(path as CString, mode) == 0
        }

        /**
         * @return the time of last access, or -1 if it doesn't exist
         */
        lastAccessed: func -> Long {
            result: FileStat
            res := lstat(path as CString, result&)
            match res {
                case 0 => result st_atime as Long
                case => -1
            }
        }

        /**
         * @return the time of last modification, or -1 if it doesn't exist
         */
        lastModified: func -> Long {
            result: FileStat
            res := lstat(path as CString, result&)
            match res {
                case 0 => result st_mtime as Long
                case => -1
            }
        }

        /**
         * @return the time of creation, or -1 if it doesn't exist
         */
        created: func -> Long {
            result: FileStat
            res := lstat(path as CString, result&)
            match res {
                case 0 => result st_ctime as Long
                case => -1
            }
        }

        /**
         * @return true if the function is relative to the current directory
         */
        relative?: func -> Bool {
            // that's a bit rough, but should work most of the time
            !path startsWith?("/")
        }

        /**
         * The absolute path, e.g. "my/dir" => "/current/directory/my/dir"
         */
        getAbsolutePath: func -> String {
            assert(path != null)
            assert(!path empty?())
            actualPath := gc_malloc(MAX_PATH_LENGTH) as CString
            ret := realpath(path, actualPath)
            if (ret == null) {
                OSException new("failed to get absolute path for " + path) throw()
            }
            actualPath toString()
        }

        /**
         * A file corresponding to the absolute path
         * @see getAbsolutePath
         */
        getAbsoluteFile: func -> File {
            actualPath := getAbsolutePath()
            if (path != actualPath) {
                return File new(actualPath)
            }
            return this
        }

        _getChildren: func <T> (T: Class) -> ArrayList<T> {
            if (!dir?()) {
                Exception new(This, "Trying to get the children of the non-directory '" + path + "'!") throw()
            }
            dir := opendir(path as CString)
            if (!dir) {
                Exception new(This, "Couldn't open directory '" + path + "' for reading!") throw()
            }

            result := ArrayList<T> new()
            entry := readdir(dir)
            while (entry != null) {
                if (!_isDirHardlink?(entry@ name)) {
                    s := String new(entry@ name, entry@ name length()) clone()
                    match T {
                        case String => result add(s)
                        case        => result add(File new(this, s))
                    }
                }
                entry = readdir(dir)
            }
            closedir(dir)
            return result

        }

        getChildrenNames: func -> ArrayList<String> {
            _getChildren (String)
        }

        getChildren: func -> ArrayList<File> {
            _getChildren (File)
        }

        mkdir: func ~withMode (mode: Int32) -> Int {
            _mkdir(path as CString, mode as ModeT)
        }

        mkfifo: func ~withMode (mode: Int32) -> Int {
            _mkfifo(path as CString, mode as ModeT)
        }
    }

}
