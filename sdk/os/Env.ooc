include stdlib | (__USE_BSD)

getenv: extern func (path: String) -> String

version (!windows) {
    setenv: extern func (key, value: String, overwrite: Bool) -> Int
    unsetenv: extern func (key: String) -> Int
}
version (windows) {
    putenv: extern func (str: String) -> Int
}

Env: class {
    get: static func (variableName: String) -> String {
        return getenv(variableName)
    }

    set: static func (key, value: String, overwrite: Bool) -> Int {
        version(windows) {
            // todo: handle overwrite
            return putenv("%s=%s" format(key, value clone()))
        }
        version(!windows) {
            return setenv(key, value, overwrite)
        }
        return -1
    }

    set: static func ~overwrite (key, value: String) -> Int {
        set(key, value, true)
    }

    unset: static func (key: String) -> Int {
        version(windows) {
            // under mingw, this unsets the key
            return putenv(key + "=")
        }
        version(!windows) {
            return unsetenv(key)
        }
        return -1
    }
    
    /* clearenv is not used since it's not part of the POSIX-2001 standard
     * and not available, for example, on OSX */
}
