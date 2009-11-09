import structs/[Array, List, ArrayList, Stack]
import io/File
import frontend/[CommandLine]
import backend/[CGenerator]

Rock: class {
    execName : static String = ""
}

main: func(args: Array<String>) {
    
    Rock execName = args get(0)
    CommandLine new(args)
    
}
