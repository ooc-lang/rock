import io/File
import os/Env

main: func {
	
	file, dir : File
	version(!windows) {
		dir  = File new("/bin")
		file = dir getChild("ls")
	}
	version(windows) {
		dir  = File new(Env get("WINDIR"))
		file = dir getChild("explorer.exe")
	}
	
	printf("%s\n\tname() = %s\n\tisFile() = %s\n\tisDir() = %s\n\tsize() = %Ld\n",
                file path, file name(), file isFile() toString(), file isDir() toString(), file size())
    printf("\tcreated() = %ld\n\tlastAccessed() = %ld\n\tlastModified() = %ld\n",
                file created(), file lastAccessed(), file lastModified())
                
	printf("%s\n\tname() = %s\n\tisFile() = %s\n\tisDir() = %s\n\tsize() = %Ld\n",
                dir path, dir name(),    dir isFile() toString(), dir isDir() toString(),  dir size())
    printf("\tcreated() = %ld\n\tlastAccessed() = %ld\n\tlastModified() = %ld\n",
                dir created(), dir lastAccessed(), dir lastModified())
	
	asdf := File new("asdf") as File
	printf("%s exists? %s\n", asdf name(), asdf exists() toString())
	printf("%s exists? %s\n", file name(), file exists() toString())
	
}
