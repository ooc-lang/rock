
import native/win32/types
import structs/ArrayList
import ../File

version(windows) {

    include windows

    // separators
    File separator = '\\'
    File pathDelimiter = ';'

    /*
     * apparently on windows, every stat operation is a find
     * This makes sense, since most fs(es) on Win32 are case-insensitive
     */
    FindData: cover from WIN32_FIND_DATA {
        attr:           extern(dwFileAttributes) Long // DWORD
        fileSizeLow:    extern(nFileSizeLow)     Long // DWORD
        fileSizeHigh:   extern(nFileSizeHigh)    Long // DWORD
        creationTime:   extern(ftCreationTime)   FileTime
        lastAccessTime: extern(ftLastAccessTime) FileTime
        lastWriteTime:  extern(ftLastWriteTime)  FileTime
        fileName:       extern(cFileName)        CString
    }

    /*
     * file attributes (incomplete list)
     */
    FILE_ATTRIBUTE_DIRECTORY,
    FILE_ATTRIBUTE_REPARSE_POINT,
    FILE_ATTRIBUTE_NORMAL : extern Long // DWORD

    /*
     * file-related functions from Win32
     */
    FindFirstFile: extern func (CString, FindData*) -> Handle
    FindNextFile: extern func(Handle, FindData*) -> Bool
    FindClose: extern func (Handle)
    GetFileAttributes: extern func (CString) -> Long
    CreateDirectory: extern func (CString, Pointer) -> Bool
    GetCurrentDirectory: extern func (Long, Pointer) -> Int

    /*
     * remove implementation
     */
    _remove: unmangled func(path: String) -> Int {
        printf("Win32: should remove file %s\n", path)
    }

    ooc_get_cwd: unmangled func -> String {
        ret := String new(File MAX_PATH_LENGTH + 1)
        if(!GetCurrentDirectory(File MAX_PATH_LENGTH, ret)) {
            Exception new("Failed to get current directory!") throw()
        }
        return ret
    }

    /*
     * Win32 implementation of File
     */
    FileWin32: class extends File {

        init: func ~win32 (=path) {
           //printf("Created FileWin32 %s, fixed path = %s, separator = %c\n", path, this path, File separator)
        }

        /**
         * @return true if the file exists and can be
         * opened for reading
         */
        exists?: func -> Bool {
            ffd := _getFindData()
            (ffd  != null)
        }

        // FIXME these 2 look deprecated and its not good practice to leave handles open as findFirst does
        findSingle: func (ffdPtr: FindData*) {
            FindClose(findFirst(ffdPtr))
        }

        findFirst: func (ffdPtr: FindData*) -> Handle {
            hFind := FindFirstFile(path as CString, ffdPtr)
            if(hFind == INVALID_HANDLE_VALUE) {
                Exception new(This, "File not found: %s" format(path)) throw()
            }
            return hFind
        }

        _getFindData: func -> FindData* {
            ffd: FindData* = gc_malloc(FindData size)
            hFind := FindFirstFile(path as CString, ffd)
            if (hFind != INVALID_HANDLE_VALUE) FindClose(hFind)
            else ffd = null
            return ffd
        }


        /**
         * @return true if it's a directory (return false if it doesn't exist)
         */
        dir?: func -> Bool {
            ffd := _getFindData()
            return (ffd  != null) && ((ffd@ attr) & FILE_ATTRIBUTE_DIRECTORY) != 0
        }

        /**
         * @return true if it's a file (ie. exists and is not a directory nor a symbolic link)
         */
        file?: func -> Bool {
            // our definition of a file: neither a directory or a link
            // (and no, FILE_ATTRIBUTE_NORMAL isn't true when we need it..)
            ffd := _getFindData()
            return (ffd != null) &&
                    (((ffd@ attr) & FILE_ATTRIBUTE_DIRECTORY    ) == 0) &&
                    (((ffd@ attr) & FILE_ATTRIBUTE_REPARSE_POINT) == 0)
        }

        /**
         * @return true if the file is a symbolic link
         */
        link?: func -> Bool {
            ffd := _getFindData()
            return (ffd != null) && ((ffd@ attr) & FILE_ATTRIBUTE_REPARSE_POINT) != 0
        }

        /**
         * @return the size of the file, in bytes
         */
        size: func -> LLong {
            ffd := _getFindData()
            return (ffd == null) ? 0 : toLLong(ffd@ fileSizeLow, ffd@ fileSizeHigh)
        }

        /**
         * @return the permissions for the owner of this file
         */
        ownerPerm: func -> Int {
            // FIXME stub
            return 0
        }

        /**
         * @return the permissions for the group of this file
         */
        groupPerm: func -> Int {
            // FIXME stub
            return 0
        }

        /**
         * @return the permissions for the others (not owner, not group)
         */
        otherPerm: func -> Int {
            // FIXME stub
            return 0
        }

        mkdir: func ~withMode (mode: Int32) -> Int {
            if(relative?()) {
                return getAbsoluteFile() mkdir()
            }

            parent := parent()
            if(!parent exists?()) parent mkdir()
            CreateDirectory(path as CString, null) ? 0 : -1
        }

        /**
         * @return the time of last access
         */
        lastAccessed: func -> Long {
            ffd := _getFindData()
            return (ffd == null) ? -1 : toTimestamp(ffd@ lastAccessTime)
        }

        /**
         * @return the time of last modification
         */
        lastModified: func -> Long {
            ffd := _getFindData()
            return (ffd == null) ? -1 : toTimestamp(ffd@ lastWriteTime)
        }

        /**
         * @return the time of creation
         */
        created: func -> Long {
            ffd := _getFindData()
            return (ffd == null) ? -1 : toTimestamp(ffd@ creationTime)
        }

        // FIXME the function is relative ? what should that mean ?
        /**
         * @return true if the function is relative to the current directory
         */
        relative?: func -> Bool {
            // that's a bit rough, but should work most of the time
            // FIXME this looks very suspicious
            path startsWith?(".") || (!path startsWith?("\\\\") && ( path length() > 1 && path[1] != ':') )
        }

        /**
         * The absolute path, e.g. "my/dir" => "/current/directory/my/dir"
         */
        getAbsolutePath: func -> String {
            if(relative?()) {
                return getCwd() + This separator + path
            } else {
                return path
            }
        }

        _isSelfOrParentDirEntry? : inline func (dir: CString) -> Bool {
            l := strlen(dir)
            return ( (l > 0 && l < 3) && (dir as Char*)@ == '.' && (l == 1 || (dir as Char* + 1)@ == '.'))
        }

        _getChildren: func <T> (param: T) -> ArrayList<T> {
            result := ArrayList<T> new()
            ffd: FindData
            hFile := FindFirstFile((path + "\\*") as CString, ffd&)
            running := (hFile != INVALID_HANDLE_VALUE)
            while(running) {
                if(!_isSelfOrParentDirEntry?(ffd fileName)) {
                    if (T == String) result add(path +  '\\' + ffd fileName)
                    else if (T == File) result add(File new(path + '\\' + ffd fileName))
                }
                running = FindNextFile(hFile, ffd&)
            }
            FindClose(hFile)
            result
        }

        /**
         * List the name of the children of this path
         * Works only on directories, obviously
         */
        getChildrenNames: func -> ArrayList<String> {
            _getChildren( path )
        }

        /**
         * List the children of this path
         * Works only on directories, obviously
         */
        getChildren: func -> ArrayList<File> {
            _getChildren ( File new ("") )
        }

    }

}
