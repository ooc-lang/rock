import structs/[Array, ArrayList]
import os/Process

main: func (args: Array<String>) {
	
	if(args size() <= 1) {
		println("Usage: ")
	}
	
    executable := "mplayer"
    version(windows) {
        executable = "notepad"
    }
    
	p := Process new([executable, args get(1)] as ArrayList<String>)
	exitCode := p execute()
	println("Process ended with exit code " + exitCode)
	return exitCode
	
}
