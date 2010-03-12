import structs/HashMap

main: func {
	
	map := HashMap<String, String> new()
    
    map put("hobo", "haba")
	("hobo = " + map get("hobo" clone())) println()
	
}
