RegexpBackend: abstract class {
	PCRE = 0, POSIX = 1, DEFAULT_TYPE = 0 : static const Int
	
	pattern: String
	
	setPattern: abstract func(pattern: String, options: Int)
	
	getPattern: func -> String {
		return pattern
	}
	
	getName: abstract func() -> String
	
	matches: abstract func(haystack: String) -> Bool
	
	matches: abstract func~withOptions(haystack: String, options: Int) -> Bool
}
