version(unix || apple) {
	include sys/wait
}

/* Constants */
WEXITSTATUS: extern func (Int) -> Int
WIFEXITED: extern func (Int) -> Int
WIFSIGNALED: extern func (Int) -> Int
WTERMSIG: extern func (Int) -> Int

/* Functions */
/* status: Int* */
wait: extern func(Int*) -> Int
/* pid: Int, status: Int, options: Int */
waitpid: extern func(Int, Int*, Int) -> Int


