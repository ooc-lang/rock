import os/Pipe, os/Process
import structs/ArrayList

main: func() {

    args := ArrayList<String> new()
    args add("echo").add("5")
    
    process := Process new(args)
    myPipe := Pipe new()
    process setStdout(myPipe)
    process execute()
    myPipe read(20) as String print()
                  
}
