import structs/HashMap

main: func {
	
	map := HashMap<String> new()
	for(i in 0..500) {
		key: String
        key = "hobo" + i toString()
		map put(key, "haba")
        if(i % 100 == 0) 
            printf("Adding key %s\n", key)
	}
	
}
