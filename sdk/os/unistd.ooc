include unistd | (__USE_GNU)

PIPE_BUF: extern Int
STDOUT_FILENO: extern Int
STDERR_FILENO: extern Int

/* Functions */
chdir: extern func(Char*) -> Int
dup2: extern func(Int, Int) -> Int
execv: extern func(Char*, Char**) -> Int
execvp: extern func(Char*, Char**) -> Int
execve: extern func(Char*, Char**, Char**) -> Int
fileno: extern func(FILE*) -> Int
fork: extern func -> Int
getpid: extern func -> UInt
pipe: extern func(arg: Int*) -> Int
isatty: extern func(fd: Int) -> Int
