include stdlib | (__USE_BSD)

getenv: extern func (path: CString) -> CString

version (!windows) {
    setenv: extern func (key, value: CString, overwrite: Bool) -> Int
    unsetenv: extern func (key: CString) -> Int
}
version (windows) {
    putenv: extern func (str: CString) -> Int
}

Env: class {
    /** returns an environment variable. if not found, it returns null */
    get: static func (variableName: String) -> String {
        x := getenv(variableName as CString)
        x != null ? x toString() : null
    }

    set: static func (key, value: String, overwrite: Bool) -> Int {
        version(windows) {
            // todo: handle overwrite
            return putenv( "%s=%s" format(key toCString(), value toCString()) toCString() )
        }
        version(!windows) {
            return setenv(key toCString(), value toCString(), overwrite)
        }
        return -1
    }

    set: static func ~overwrite (key, value: String) -> Int {
        set(key, value, true)
    }

    unset: static func (key: String) -> Int {
        version(windows) {
            // under mingw, this unsets the key
            return putenv((key + "=") toCString())
        }
        version(!windows) {
            return unsetenv(key toCString())
        }
        return -1
    }

    /* clearenv is not used since it's not part of the POSIX-2001 standard
     * and not available, for example, on OSX */
}
