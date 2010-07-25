import text/Buffer
import structs/ArrayList
/*  
	extended Buffer class by rofl0r
	-------------------------------
	
	highly optimized for best possible performance,	gcc will do the rest
	will be extended more in the future
	
	the main advantage of Buffer vs String is that the Buffer can store the length, 
	so it doesnt call strlen on every use, which can mean thousands of cpu cycles
	additionally, it can be used to handle data which contains \0
	
	a slight disadvantage is that it is allocated on the heap, so if you just want
	to print "hello world" it may be overkill.
	
	allows to search for a given string/Buffer:
		
	buf : ExtBuffer = ExtBuffer new("110111") .setCaseSensitive(true) .initSearch("1")
	while (buf find()) {
		println ("found at pos " + ((buf pos) toString()) )
	}	
	println("pos finally at" + (buf pos) toString())
	
	allows to replace a string:
	buf := ExtBuffer new("windows windows windows") 
	buf setCaseSensitive(true) 
	nbuf := buf replaceAll( "windows", "linux" )
	if (nbuf) println("finally: " + nbuf data as String)	
	
	allows to split/explode to an arraylist of extbuffers
	x := buf explode( Buffer new(" ") )
	if (x) for (item in x) item toString() println()
	add that to the replace example above
	
	allows to read contents from file / write to file (non \0 sensitive)
	
	future plans: what ever is missing ...	
		
*/

ExtBuffer: class extends Buffer {
	
	pos : SizeT
	searchCaseSensitive : Bool = true
	searchBuffer : Buffer
	newSearch : Bool = true
	
	init: super func ~withCapa
	init: super func ~str
	init: super func ~strWithLength

	
	clone: func -> This { 
		result := This new(size) 
		memcpy(result data as Char*, data as Char *, size) 
		result pos = pos
		result searchBuffer = (searchBuffer) ? searchBuffer clone() : null
		result searchCaseSensitive = this searchCaseSensitive
		result newSearch = newSearch		
		return result		
	}
		
	checkBounds: func -> Bool {
		return (pos < size)
	}	
	
	posPtr: func -> Char* {
		if (checkBounds()) {
			return ((data as Char*) + pos)
		}	
		else { 
			return null
		}	
	}
	
	posPtrInc: func -> Char* {
		ptr := posPtr()
		if (ptr != null) {
			pos+=1
		}	
		return ptr
	}
	
    get: func ~chrFromPos -> Char {
        if(!checkBounds()) {
            Exception new(This, "Buffer overflow! Offset is larger than buffer size.") throw()
        }
        return data[pos]
    }	
	
	getInc: func -> Char {
        if(!checkBounds()) {
            Exception new(This, "Buffer overflow! Offset is larger than buffer size.") throw()
        }
        pos += 1
        return data[pos-1]	
	}

	resetSearch: func {
		pos = 0
		newSearch = true
	}
	
	setCaseSensitive: func (=searchCaseSensitive) {}
	
	initSearch: func ~str (what: String) {	
		initSearch ( what, what length() )
	}
	
	initSearch: func ~strWithLength (what: String, length: SizeT) {	
		initSearch ( Buffer new ( what, length  ))		 
	}

	initSearch: func ~buf (=searchBuffer) {			
		resetSearch()		
	}
	
	/*  side effects: pos will be set to array index on match
		and to 0 when not found */
	find : func -> Bool {	
		if (searchBuffer == null) Exception new(This, "find called without initSearch") throw()
		//("x" + (data as String) + "x") println ()
		//("x" + (searchBuffer data as String) + "x") println()
		if (!newSearch) pos += searchBuffer size // add searchterm size to pos on continued searches, otherwise we would find the last result again
		else newSearch = false
		
		found : Bool		
		maxpos : SSizeT = size - searchBuffer size // need a signed type here
		
		if ((maxpos) < 0) {
			pos = 0
			return false
		}		
		
		i : SizeT = 0
		
		while ((i + pos) <= maxpos) {
			found = true
			for (j in 0..(searchBuffer size)) {
				if (searchCaseSensitive) {
					if ( (data as Char* + pos + i + j)@ != (searchBuffer data as Char* + j)@ ) {
						found = false
						break
					}				
				} else {
					if ( (data as Char* + pos + i + j)@ toUpper() != (searchBuffer data as Char* + j)@ toUpper() ) {
						found = false
						break
					}				
				}
			}				
			if (found) {
				pos += i
				return true 
			}
			i += 1	
		} 			
		pos = 0	
		return false	
	}
	
	/* returns a list of positions where buffer has been found, or an empty list if not */
	searchResults: func ( what : Buffer) -> ArrayList <SizeT> {
		// we make a list of positions returned, maxed out to maximum possible capacity 
		// (means maximum amount of possible search results)
		// so we dont lose cpu cycles for realloc
		// mem usage will only get slightly higher with really huge strings
		// but still far below what we're used to from java/.net 
		if (what == null || what size == 0) return ArrayList <SizeT> new(0)
		result := ArrayList <SizeT> new (size / what size)
		initSearch(what)
		while (find()) result add (pos)
		return result	
	}
	
	replaceAll: func ~str (what, whit : String) -> This {
		return replaceAll ( what, what length(), whit, whit length() )
	}
	
	replaceAll: func ~strWithLength (what:String, whatLength: SizeT, whit : String, whitLength: SizeT) -> This {
		return replaceAll (Buffer new ( what, whatLength), Buffer new ( whit, whitLength ) )
	}	
	
	// quickest possible replace algorithm, uses only 2 malloc's and 1 linear read as well as 1 linear write
	// "this" is the haystack, "what" the needle, "whit" the replacement
	replaceAll: func (what, whit : Buffer) -> This {
		if (what == null || what size == 0 || whit == null) return clone()
			
		l := searchResults( what )
		 
		if (l == null || l size() == 0) return clone()
		result := This new( size + (whit size * l size) - (what size * l size) )
		
		sstart: SizeT = 0 //source (this) start pos
		rstart: SizeT = 0 //result start pos 
		
		for (item in l) {
			
			sdist := item - sstart // bytes to copy
			memcpy(result data as Char* + rstart, data as Char* + sstart, sdist)	
			sstart += sdist		
			rstart += sdist
			memcpy(result data as Char* + rstart, whit data as Char*, whit size)
			sstart += what size
			rstart += whit size 	
			
		}	
		// copy remaining last piece of source	
		sdist := size - sstart
		memcpy(result data as Char* + rstart, data as Char* + sstart, sdist)	
		
		return result
		
	}
	
	explode: func ~str (delimiter: String) -> ArrayList <This> {
		return explode( delimiter, delimiter length() )
	}

	explode: func ~strWithLength (delimiter: String, length: SizeT) -> ArrayList <This> {
		return explode( Buffer new ( delimiter, length ) )
	}
	
	explode: func (delimiter:Buffer) -> ArrayList <This> {
		
		l := searchResults(delimiter) 
		result := ArrayList <This> new(l size()) 
		sstart: SizeT = 0 //source (this) start pos
		for (item in l) {
			sdist := item - sstart // bytes to copy
			b := This new ((data as Char* + sstart) as String, sdist)
			result add ( b ) 
			sstart += sdist + delimiter size
		}
		sdist := size - sstart // bytes to copy
		b := This new ((data as Char* + sstart) as String, sdist)
		result add ( b ) 		
		return result
	}
	
	fromFile: func (fileName: String) -> Bool {
		STEP_SIZE : SizeT = 4096				
		file := FStream open(fileName, "rb")
		if (!file || file error()) return false
		len := file size()
		checkLength(len + 1)	
		data[len] = '\0'
		pos = 0
		while (len / STEP_SIZE > 0) {
			retv := file read((data as Char* + pos) as Pointer, STEP_SIZE)
			if (retv != STEP_SIZE || file error()) {
				file close()
				return false
			}	
			len -= retv
			pos += retv
		}
		if (len) file read((data as Char* + pos) as Pointer, len)	
		size += len	
		return (file error()==0) && (file close() == 0)
	}
	
	toFile: func (fileName: String, doAppend: Bool) -> Bool {
		STEP_SIZE : SizeT = 4096				
		file := FStream open(fileName, doAppend ? "ab" : "wb") 
		if (!file || file error()) return false
		pos = 0
		togo := size
		while (togo / STEP_SIZE > 0) {
			retv := file write ((data as Char* + pos) as String, STEP_SIZE)
			if (retv != STEP_SIZE || file error()) {
				file close()
				return false
			}	
			togo -= retv
			pos  += retv			
		}
		if (togo) file write((data as Char* + pos) as String, togo)	
		return (file error() == 0) && (file close()==0 )					
	}
	
}

