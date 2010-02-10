import io/[File, FileWriter] into F
import io/FileReader into F

main: func {

    f := F File new("test.txt")

    writer := F FileWriter new(f)
    writer write("yay")
    writer close()

    reader := F FileReader new(f)
    contents := reader readLine()
    reader close()
    
    contents println()
    f remove()

}
