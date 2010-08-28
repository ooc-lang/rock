import structs/[HashMap, ArrayList, List]
import ../[Env, Process, wait, unistd, Pipe, PipeReader]
import PipeUnix

version(unix || apple) {

include errno

errno : extern Int

/**
   Process implementation for *nix

   :author: Yannic Ahrens (showstopper)
   :author: Amos Wenger (nddrylliog)
 */
ProcessUnix: class extends Process {

    init: func ~unix (=args) {
        //this args add(null) // execvp wants NULL to end the array
    }

    /**
       Wait for the process to end. Bad things will happen if you
       haven't called `executeNoWait` before.
     */
    wait: func -> Int {
		cprintf("Waiting\n")
		
        status: Int
        result := -555
        if(stdIn != null) {
            stdIn close('w')
        }
        waitpid(-1, status&, 0)
        cprintf("waitpid returned!\n")
        if (WIFEXITED(status)) {
            result = WEXITSTATUS(status)
            if (stdOut != null) {
                stdOut close('w')
            }
            if (stdErr != null) {
                stdErr close('w')
            }
        }
        return result
    }

    /**
       Execute the process without waiting for it to end.
       You have to call `wait` manually.
    */
    executeNoWait: func {
		"executeNoWait" println()
		
        pid := fork()
        cprintf("pid = %d\n", pid)
        
        if (pid == 0) {
			"Dup'ing stdin" println()
            if (stdIn != null) {
                stdIn close('w')
                dup2(stdIn as PipeUnix readFD, 0)
            }
            "Dup'ing stdout" println()
            if (stdOut != null) {
                stdOut close('r')
                dup2(stdOut as PipeUnix writeFD, 1)
            }
            "Dup'ing stderr" println()
            if (stdErr != null) {
                stdErr close('r')
                dup2(stdErr as PipeUnix writeFD, 2)
            }

            /* amend the environment if needed */
            if(env) {
				"Amending env" println()
                for(key in env getKeys()) {
                    Env set(key, env[key], true)
                }
            }

            /* set a new cwd? */
            if(cwd != null) {
				"Changing cwd" println()
                chdir(cwd as CString)
            }

            /* run the stuff. */
            "Converting args" println()
            cArgs : CString * = gc_malloc(Pointer size * (args size() + 1))
            args size() times(|i|
				cArgs[i] = args[i] toCString()
				cprintf("Arg %d = %s\n", i, cArgs[i])
            )
            cArgs[args size()] = null // null-terminated - makes sense
            
            cprintf("Calling execvp\n")
            stdout flush()
            execvp(cArgs[0], cArgs)
            exit(errno); // don't allow the forked process to continue if execvp fails
        }
    }

}

}
