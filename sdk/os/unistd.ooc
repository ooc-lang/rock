include unistd | (__USE_GNU)

/* Functions */
chdir: extern func(CString) -> Int
dup2: extern func(Int, Int) -> Int
execv: extern func(CString, CString*) -> Int
execvp: extern func(CString, CString*) -> Int
execve: extern func(CString, CString*, CString*) -> Int
fileno: extern func(FILE*) -> Int
fork: extern func -> Int
getpid: extern func -> UInt
pipe: extern func(arg: Int*) -> Int
isatty: extern func(fd: Int) -> Int
