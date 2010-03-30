
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
        fileName:       extern(cFileName)        String
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
    FindFirstFile: extern func (String, FindData*) -> Handle
    FindNextFile: extern func(Handle, FindData*) -> Bool
    FindClose: extern func (Handle)
    GetFileAttributes: extern func (String) -> Long
    CreateDirectory:extern func (String, Pointer) -> Bool

    /*
     * remove implementation
     */
    _remove: unmangled func(path: String) -> Int {
        printf("Win32: should remove file %s\n", path)
    }

    /*
     * Win32 implementation of File
     */
    FileWin32: class extends File {

        init: func ~win32 (=path) {}

        /**
         * @return true if the file exists and can be
         * opened for reading
         */
        exists: func -> Bool {
            (0xFFFFFFFF != GetFileAttributes(path))
        }

        findSingle: func (ffdPtr: FindData*) {
            hFind := findFirst(ffdPtr)
            if(hFind == INVALID_HANDLE_VALUE) {
                Exception new("[findSingle] Got invalid handle for file %s" format(path)) throw()
            }
            FindClose(hFind)
        }

        findFirst: func (ffdPtr: FindData*) -> Handle {
            hFind := FindFirstFile(path, ffdPtr)
            if(hFind == INVALID_HANDLE_VALUE) {
                Exception new("[findFirst] Got invalid handle for file %s" format(path)) throw()
            }
            return hFind
        }

        /**
         * @return true if it's a directory
         */
        isDir: func -> Bool {
            ffd: FindData
            findSingle(ffd&)
            return ((ffd attr) & FILE_ATTRIBUTE_DIRECTORY)
        }

        /**
         * @return true if it's a file (ie. not a directory nor a symbolic link)
         */
        isFile: func -> Bool {
            ffd: FindData
            findSingle(ffd&)
            // our definition of a file: neither a directory or a link
            // (and no, FILE_ATTRIBUTE_NORMAL isn't true when we need it..)
            return (((ffd attr) & FILE_ATTRIBUTE_DIRECTORY    ) == 0) &&
                   (((ffd attr) & FILE_ATTRIBUTE_REPARSE_POINT) == 0)
        }

        /**
         * @return true if the file is a symbolic link
         */
        isLink: func -> Bool {
            ffd: FindData
            findSingle(ffd&)
            return ((ffd attr) & FILE_ATTRIBUTE_REPARSE_POINT)
        }

        /**
         * @return the size of the file, in bytes
         */
        size: func -> LLong {
            ffd: FindData
            findSingle(ffd&)
            return toLLong(ffd fileSizeLow, ffd fileSizeHigh)
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
            if(isRelative()) {
                getAbsoluteFile() mkdir()
                return
            }

            parent := parent()
            if(!parent exists()) parent mkdir()
            CreateDirectory(path, null) ? 0 : -1
        }

        /**
         * @return the time of last access
         */
        lastAccessed: func -> Long {
            ffd: FindData
            findSingle(ffd&)
            return toTimestamp(ffd lastAccessTime)
        }

        /**
         * @return the time of last modification
         */
        lastModified: func -> Long {
            ffd: FindData
            findSingle(ffd&)
            return toTimestamp(ffd lastWriteTime)
        }

        /**
         * @return the time of creation
         */
        created: func -> Long {
            ffd: FindData
            findSingle(ffd&)
            return toTimestamp(ffd creationTime)
        }

        /**
         * @return true if the function is relative to the current directory
         */
        isRelative: func -> Bool {
            // that's a bit rough, but should work most of the time
            path startsWith(".") || (!path startsWith("\\\\") && path[1] != ':')
        }

        /**
         * The absolute path, e.g. "my/dir" => "/current/directory/my/dir"
         */
        getAbsolutePath: func -> String {
            if(isRelative()) {
                return getCwd() + This separator + path
            } else {
                return path
            }
        }

        /**
         * List the name of the children of this path
         * Works only on directories, obviously
         */
        getChildrenNames: func -> ArrayList<String> {
            result := ArrayList<String> new()
            ffd: FindData
            hFile := FindFirstFile(path + "\\*", ffd&)
            running := (hFile != INVALID_HANDLE_VALUE)
            while(running) {
                if(ffd fileName != "." && ffd fileName != "..") {
                    result add(path +  '\\' + ffd fileName)
                }
                running = FindNextFile(hFile, ffd&)
            }
            FindClose(ffd&)

            result
        }

        /**
         * List the children of this path
         * Works only on directories, obviously
         */
        getChildren: func -> ArrayList<This> {
            result := ArrayList<This> new()
            ffd: FindData
            hFile := FindFirstFile(path + "\\*", ffd&)
            running := (hFile != INVALID_HANDLE_VALUE)
            while(running) {
                if(ffd fileName != "." && ffd fileName != "..") {
                    result add(File new(path + '\\' + ffd fileName))
                }
                running = FindNextFile(hFile, ffd&)
            }
            FindClose(ffd&)

            result
        }

    }

}
