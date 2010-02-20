import io/[FileReader,FileWriter]

BUFFER_LENGTH := const 10

main: func {
    hosts := FileReader new("/etc/hosts")
    copy := FileWriter new("hosts-copy")

    buffer := gc_malloc(BUFFER_LENGTH) as String
    while(hosts hasNext()) {
        copy write(buffer, hosts read(buffer, 0, BUFFER_LENGTH - 1))
    }
}
