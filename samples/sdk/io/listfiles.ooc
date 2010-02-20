import io/File, structs/[Array, ArrayList], os/Terminal

main: func (args: Array<String>) {

    path := "."
    if(args size() > 1)
        path = args get(1)

    for(f: File in (File new(path) getChildren())) {
        //f = f getAbsoluteFile()

        Terminal setAttr(Attr bright)
        Terminal setFgColor(match {
            case f isDir()  => Color blue
            case f isLink() => Color cyan
            case            => Terminal setAttr(Attr reset); Color white
        })
        if(f isFile() && (f ownerPerm() & 1 || f groupPerm() & 1 || f otherPerm() & 1)) {
            Terminal setAttr(Attr bright)
            Terminal setFgColor(Color green)
        }
        
        printf("%s  ", f name())
    }

    Terminal reset()
    println()

}
