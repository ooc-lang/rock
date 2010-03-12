import structs/HashMap

main: func (argc: Int, argv: String*) {
	
	ht := HashMap<String, String> new()


	/* Testing contains method */
	printf("Contains foo? %s\n\n", ht contains("foo") ? "yes" : "no") 

	/* Test put/contains/get */
	printf("Adding foo -> bar\n") 
	ht put("foo", "bar") 
	printf("Contains foo now? %s\n", ht contains("foo") ? "yes" : "no") 
	printf("Value: %s\n\n", ht get("foo")) 

	/* Test overwriting with put */
	printf("Overwriting foo with baz\n") 
	ht put("foo", "baz") 
	printf("%s\n\n", ht get("foo")) 

	/* Try to resize the table, see if it worked */
	printf("Resizing table\n") 
	ht resize(50) 
	printf("Still contains foo? %s\n\n", ht contains("foo") ? "yes" : "no") 

	/* Add a few keys */
	printf("Adding keys bar, baz, quux\n") 
	ht put("bar", "bar") 
	ht put("baz", "baz") 
	ht put("quux", "quux") 

	/* Test removal */
	printf("Removing foo\n") 
	ht remove("foo") 
	printf("Contains foo now? %s\n\n", ht contains("foo") ? "yes" : "no") 

	/* Check out the keys */
	printf("Keys: ") 
	//for(key: String in ht keys) {
    for(key: String in ht getKeys()) {
		printf("%s=%s ", key, ht get(key))
	}
	printf("\n") 

}

