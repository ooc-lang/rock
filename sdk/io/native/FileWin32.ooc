
import native/win32/[types, errors]
import structs/ArrayList
import ../File

version(windows) {

    include windows | (_WIN32_WINNT=0x0500)

    // separators
    File separator = '\\'
    File pathDelimiter = ';'

    PATHCCH_MAX_CCH: extern SizeT

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
    FILE_ATTRIBUTE_NORMAL,
    INVALID_FILE_ATTRIBUTES: extern Long // DWORD

    /*
     * file-related functions from Win32
     */
    FindFirstFile: extern(FindFirstFileA) func (CString, FindData*) -> Handle
    FindNextFile: extern func (Handle, FindData*) -> Bool
    FindClose: extern func (Handle)
    GetFileAttributes: extern func (CString) -> ULong
    CreateDirectory: extern func (CString, Pointer) -> Bool
    GetCurrentDirectory: extern func (ULong, Pointer) -> Int
    GetFullPathName: extern func (CString, ULong, CString, CString) -> ULong
    GetLongPathName: extern func (CString, CString, ULong) -> ULong
    DeleteFile: extern func (CString) -> Bool
    RemoveDirectory: extern func (CString) -> Bool

    /*
     * remove implementation
     */
    _remove: unmangled func (file: File) -> Bool {
        if (file dir?()) {
            return RemoveDirectory(file path)
        }
        return DeleteFile(file path)
    }

    ooc_get_cwd: unmangled func -> String {
        ret := Buffer new(File MAX_PATH_LENGTH + 1)
        bytesWritten := GetCurrentDirectory(File MAX_PATH_LENGTH, ret data)
        if (bytesWritten == 0) OSException new("Failed to get current directory!") throw()
        ret setLength(bytesWritten)
        String new(ret)
    }

    /*
     * Win32 implementation of File
     */
    FileWin32: class extends File {

        init: func ~win32 (.path) {
            this path = _normalizePath(path)
        }

        _getFindData: func -> (FindData, Bool) {
            ffd: FindData
            hFind := FindFirstFile(path toCString(), ffd&)
            if (hFind != INVALID_HANDLE_VALUE) FindClose(hFind)
            else {
                return (ffd, false)
            }
            return (ffd, true)
        }

        /**
         * @return true if it's a directory (return false if it doesn't exist)
         */
        dir?: func -> Bool {
            (ffd, ok) := _getFindData()
            return (ok) && ((ffd attr) & FILE_ATTRIBUTE_DIRECTORY) != 0
        }

        /**
         * @return true if it's a file (ie. exists and is not a directory nor a symbolic link)
         */
        file?: func -> Bool {
            // our definition of a file: neither a directory or a link
            // (and no, FILE_ATTRIBUTE_NORMAL isn't true when we need it..)
            (ffd, ok) := _getFindData()
            return (ok) &&
                    (((ffd attr) & FILE_ATTRIBUTE_DIRECTORY    ) == 0) &&
                    (((ffd attr) & FILE_ATTRIBUTE_REPARSE_POINT) == 0)
        }

        /**
         * @return true if the file is a symbolic link
         */
        link?: func -> Bool {
            (ffd, ok) := _getFindData()
            return (ok) && ((ffd attr) & FILE_ATTRIBUTE_REPARSE_POINT) != 0
        }

        /**
         * @return the size of the file, in bytes
         */
        getSize: func -> LLong {
            (ffd, ok) := _getFindData()
            return (ok) ? toLLong(ffd fileSizeLow, ffd fileSizeHigh) : 0
        }

        /**
         * @return true if the file exists
         */
        exists?: func -> Bool {
            res := GetFileAttributes(path as CString)
            (res != INVALID_FILE_ATTRIBUTES)
        }

        /**
         * @return the permissions for the owner of this file
         */
        ownerPerm: func -> Int {
            // Win32 permissions are not unix-like
            return 0
        }

        /**
         * @return the permissions for the group of this file
         */
        groupPerm: func -> Int {
            // Win32 permissions are not unix-like
            return 0
        }

        /**
         * @return the permissions for the others (not owner, not group)
         */
        otherPerm: func -> Int {
            // Win32 permissions are not unix-like
            return 0
        }

        /**
        * @return true if a file is executable by the current owner
        */
        executable?: func -> Bool {
            // Win32 has no *simple* concept of 'executable' bit
            // we'd have to handle ACLs, and that's a nasty can of worms.
            // For now, `executable?` and `setExecutable` are enough
            // to set basic permissions when creating files on *nix.
            // See discussion on this commit for more details:
            // https://github.com/nddrylliog/rock/commit/c6b8e9a23079451f2d6c6964cace8ff786f4d434
            false
        }

        /**
        * set the executable bit on this file's permissions for
        * current user, group, and other.
        */
       setExecutable: func (exec: Bool) -> Bool {
            // see comment for 'executable?'
            false
        }

        mkdir: func ~withMode (mode: Int32) -> Int {
            if (relative?()) {
                return getAbsoluteFile() mkdir()
            }

            p := parent
            if (!p exists?()) parent mkdir()
            CreateDirectory(path toCString(), null) ? 0 : -1
        }

        mkfifo: func ~withMode (mode: Int32) -> Int {
            fprintf(stderr, "FileWin32: stub mkfifo")
        }

        /**
         * @return the time of last access
         */
        lastAccessed: func -> Long {
            (ffd, ok) := _getFindData()
            return (ok) ? toTimestamp(ffd lastAccessTime) : -1
        }

        /**
         * @return the time of last modification
         */
        lastModified: func -> Long {
            (ffd, ok) := _getFindData()
            return (ok) ? toTimestamp(ffd lastWriteTime) : -1
        }

        /**
         * @return the time of creation
         */
        created: func -> Long {
            (ffd, ok) := _getFindData()
            return (ok) ? toTimestamp(ffd creationTime) : -1
        }

        /**
         * @return true if the function is relative to the current directory
         */
        relative?: func -> Bool {
            // that's a bit rough, but should work most of the time
            !path startsWith?("/") && (path length() <= 1 || path[1] != ':')
        }

        /**
         * The absolute path, e.g. "my/dir" => "C:\current\directory\my\dir"
         */
        getAbsolutePath: func -> String {
            fullPath := Buffer new(File MAX_PATH_LENGTH)
            fullPath setLength(GetFullPathName(path toCString(), File MAX_PATH_LENGTH, fullPath data, null))
            _normalizePath(fullPath toString())
        }

        /**
         * The long path, ie. with correct casing. e.g. the final path will
         * contain the original case of the concerned folder/files.
         */
        getLongPath: func -> String {
            abs := getAbsoluteFile()
            if (!abs exists?()) {
                Exception new(class, "Called File getLongPath on non-existing file %s" format(abs path)) throw()
            }
            longPath := Buffer new(File MAX_PATH_LENGTH)
            longPath setLength(GetLongPathName(abs path toCString(), longPath data, File MAX_PATH_LENGTH))
            longPath toString()
        }

        _getChildren: func <T> (T: Class) -> ArrayList<T> {
            result := ArrayList<T> new()
            ffd: FindData
            searchPath := path + "\\*"
            hFile := FindFirstFile(searchPath toCString(), ffd&)

            if (hFile == INVALID_HANDLE_VALUE) {
              return result
            }

            running := true
            while (running) {
                if (!_isDirHardlink?(ffd fileName)) {
                    s := ffd fileName toString()
                    match T {
                        case String => result add(s)
                        case        => result add(File new(this, s))
                    }
                }
                running = FindNextFile(hFile, ffd&)
            }
            FindClose(hFile)
            result
        }

        _normalizePath: static func (in: String) -> String {
            // normalize "c:/Dev" to "C:\Dev"
            result := in replaceAll("/", "\\")
            if (result size >= 2 && result[1] == ':') {
                // normalize "c:\Dev" to "C:\Dev"
                result = result[0..1] toUpper() + result[1..-1]
            }
            result
        }

        /**
         * List the name of the children of this path
         * Works only on directories, obviously
         */
        getChildrenNames: func -> ArrayList<String> {
            _getChildren( String )
        }

        /**
         * List the children of this path
         * Works only on directories, obviously
         */
        getChildren: func -> ArrayList<File> {
            _getChildren ( File )
        }

    }

}
