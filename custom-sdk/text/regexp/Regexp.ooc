import text/regexp/[RegexpBackend, PCRE, POSIX]

Regexp: class {
	regexpBackend: RegexpBackend
	type: Int

	init: func {
		type = RegexpBackend DEFAULT_TYPE
		setup()
	}
	
	init: func~withType(=type) {
		setup()
	}
	
	init: func~withPattern(pattern: String) {
		this()
		setPattern(pattern)
	}
	
	init: func~withPatternAndOptions(pattern: String, options: Int) {
		this()
		setPattern(pattern, options)
	}
	
	setup: func {
		if (type == RegexpBackend PCRE)
			regexpBackend = PCRE new()
		else if (type == RegexpBackend POSIX)
			regexpBackend = POSIX new()
	}
	
	setPattern: func~withOptions(pattern: String, options: Int) {
		regexpBackend setPattern(pattern, options)
	}
	
	setPattern: func(pattern: String) {
		setPattern(pattern, 0)
	}
	
	getPattern: func -> String {
		return regexpBackend getPattern()
	}
	
	matches: func(haystack: String) -> Bool {
		return regexpBackend matches(haystack)
	}
	
	matches: func~withOptions(haystack: String, options: Int) -> Bool {
		return regexpBackend matches(haystack, options)
	}

	getEngine: func -> Int { type }
	
	getEngineName: func -> String { regexpBackend getName() }
	
}
/*
main: func {
	rx := Regexp new("^Hello \\w+$", PCRE CASELESS)
	printf("Engine: %d\n", rx getEngine());
	printf("Pattern: %s\n", rx getPattern());
	
	if (rx matches("HELLO world"))
		printf("Matches!\n")
	else
		printf("No match\n")
		
	// if (string =~ /^Hello, (\w+)/i)
	
	tryLoop()
		
}
*/
/**
 * Check that the regexp is in fact freed. A dot is displayed each time
 * one is allocated, and a caret is displayed each time one his freed =)
 */
/*tryLoop: func {

    PCRE_DEBUG = true
    
    for(i in 0..10_000) {
        rx := Regexp new("^Hello \\w+$", PCRE CASELESS)
        if(rx matches("HELLO world")) {
            printf(".")
        }
    }
    
}
*/
