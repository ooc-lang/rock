include stdlib | (__USE_BSD)

getenv: extern func (path: Char*) -> Char*

version (!windows) {
    setenv: extern func (key, value: Char*, overwrite: Bool) -> Int
    unsetenv: extern func (key: Char*) -> Int
}
version (windows) {
    putenv: extern func (str: Char*) -> Int
}

Env: class {
    get: static func (variableName: String) -> String {
        return getenv(variableName) as String
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
