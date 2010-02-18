import structs/HashMap

main: func {
	
	map := HashMap<String> new()
	map put("hobo", "haba")
	("hobo = " + map get("hobo")) println()
	
}
