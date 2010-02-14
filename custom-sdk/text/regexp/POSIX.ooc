import text/regexp/RegexpBackend

POSIX: class extends RegexpBackend {
	setPattern: func(pattern: String, options: Int) {
		this pattern = pattern
	}
	
	getName: func -> String { "POSIX" }
	
	matches: func(haystack: String) -> Bool {
		return false
	}
	
	matches: func~withOptions(haystack: String, options: Int) -> Bool {
		return false
	}
}
