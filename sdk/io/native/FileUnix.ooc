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

realpath: extern func(path: CString, resolved: CString) -> CString

version(linux) {
    include unistd | (__USE_BSD), sys/stat | (__USE_BSD), sys/types | (__USE_BSD), stdlib | (__USE_BSD), limits
}
version(!linux) {
    include unistd, sys/stat, sys/types, stdlib
}

version(unix || apple) {

    // separators
    File separator = '/'
    File pathDelimiter = ':'

    _getcwd: extern(getcwd) func(buf: CString, size: SizeT) -> CString

    ooc_get_cwd: unmangled func -> String {
        result := Buffer new(File MAX_PATH_LENGTH)
        if(!_getcwd(result data as CString, File MAX_PATH_LENGTH)) {
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

    S_ISDIR: extern func(...) -> Bool
    S_ISREG: extern func(...) -> Bool
    S_ISLNK: extern func(...) -> Bool
    S_IRWXU, S_IRWXG, S_IRWXO: extern Int // constants

    lstat: extern func(CString, FileStat*) -> Int
    _mkdir: extern(mkdir) func(CString, ModeT) -> Int
    remove: extern func(path: CString) -> Int
    _remove: unmangled func(path: String) -> Int {
        remove(path)
    }

    /*
     * Unix (POSIX) implementation of File
     */
    FileUnix: class extends File {

        init: func ~unix (=path) {}

        _getFileStat: func -> FileStat {
            result: FileStat
            lstat(path as CString, result&)
            return result
        }

        /**
         * @return true if it's a directory
         */
        dir?: func -> Bool {
            return S_ISDIR(_getFileStat() st_mode)
        }

        /**
         * @return true if it's a file (ie. not a directory nor a symbolic link)
         */
        file?: func -> Bool {
            return S_ISREG(_getFileStat() st_mode)
        }

        /**
         * @return true if the file is a symbolic link
         */
        link?: func -> Bool {
            return S_ISLNK(_getFileStat() st_mode)
        }

        /**
         * @return the size of the file, in bytes
         */
        getSize: func -> LLong {
            return _getFileStat() st_size as LLong
        }

        /**
         * @return the permissions for the owner of this file
         */
        ownerPerm: func -> Int {
            return ((_getFileStat() st_mode) & S_IRWXU) as Int >> 6
        }

        /**
         * @return the permissions for the group of this file
         */
        groupPerm: func -> Int {
            return ((_getFileStat() st_mode) & S_IRWXG) as Int >> 3
        }

        /**
         * @return the permissions for the others (not owner, not group)
         */
        otherPerm: func -> Int {
            return ((_getFileStat() st_mode) & S_IRWXO) as Int
        }

        /**
         * @return the time of last access, or -1 if it doesn't exist
         */
        //FIXME maybe the exists call is redundant
        lastAccessed: func -> Long {
            if(!exists?()) return -1
            return _getFileStat() st_atime as Long
        }

        /**
         * @return the time of last modification, or -1 if it doesn't exist
         */
        //FIXME maybe the exists call is redundant
        lastModified: func -> Long {
            if(!exists?()) return -1
            return _getFileStat() st_mtime as Long
        }

        /**
         * @return the time of creation, or -1 if it doesn't exist
         */
        //FIXME maybe the exists call is redundant
        created: func -> Long {
            if(!exists?()) return -1
            return _getFileStat() st_ctime as Long
        }

        /**
         * @return true if the function is relative to the current directory
         */
        relative?: func -> Bool {
            // that's a bit rough, but should work most of the time
            path startsWith?(".") || !path startsWith?("/")
        }

        /**
         * The absolute path, e.g. "my/dir" => "/current/directory/my/dir"
         */
        getAbsolutePath: func -> String {
            assert(path != null)
            assert(!path empty?())
            actualPath := Buffer new(MAX_PATH_LENGTH)
            ret := realpath(path toCString(), actualPath toCString())
            if (ret == null) OSException new("failed to get absolute path for " + path) throw()
            String new(ret, ret length())
        }

        /**
         * A file corresponding to the absolute path
         * @see getAbsolutePath
         */
        getAbsoluteFile: func -> File {
            actualPath := getAbsolutePath()
            if(path != actualPath) {
                return File new(actualPath)
            }
            return this
        }

        _getChildren: func <T> (T: Class) -> ArrayList<T> {
            if(!dir?()) {
                Exception new(This, "Trying to get the children of the non-directory '" + path + "'!") throw()
            }
            dir := opendir(path as CString)
            if(!dir) {
                Exception new(This, "Couldn't open directory '" + path + "' for reading!") throw()
            }

            result := ArrayList<T> new()
            entry := readdir(dir)
            while(entry != null) {
                if(!_isDirHardlink?(entry@ name)) {
                    s := String new(entry@ name, entry@ name length()) clone()
                    candidate: T = (T == String) ? s : File new(this, s)
                    result add(candidate)
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

    }

}
