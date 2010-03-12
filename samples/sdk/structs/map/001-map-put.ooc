import structs/HashMap

main: func {
	
	map := HashMap<String, String> new()
	for(i in 0..500) {
		key: String
        key = "hobo" + i toString()
		map put("hobo", "haba")
        if(i % 100 == 0) 
            printf("Adding key %s\n", key)
	}
	
}
