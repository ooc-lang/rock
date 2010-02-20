import io/FileReader

main: func {
	fr := FileReader new("/etc/hosts") 
	
	while (fr hasNext())
		fr read() print()
	
}
