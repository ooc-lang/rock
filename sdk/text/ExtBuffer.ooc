import text/Buffer
import structs/ArrayList
/*  
	extended Buffer class by rofl0r
	-------------------------------
	
	highly optimized for best possible performance,	gcc will do the rest
	will be extended more in the future
	
	this is what i want String to be...
	
	allows to search for a given string/Buffer:
		
	buf : ExtBuffer = ExtBuffer new("110111") .setCaseSenisitive(true) .initSearch("1")
	while (buf find()) {
		println ("found at pos " + ((buf pos) toString()) )
	}	
	println("pos finally at" + (buf pos) toString())
	
	allows to replace a string:
	buf := ExtBuffer new("windows windows windows") 
	buf setCaseSensitive(true) 
	nbuf := buf replaceAll( Buffer new ("windows"), Buffer new ("linux") )
	if (nbuf) println("finally: " + nbuf data as String)	
	
	future plans: explode, fromFile, toFile
	
	TODO maybe add \0 automatically at the end of every Buffer, so the pointer can
	directly be passed to C functions in every case
		
*/

ExtBuffer: class extends Buffer {
	
	pos : SizeT
	searchCaseSensitive : Bool = true
	searchBuffer : Buffer
	
	init: super func ~withCapa
	init: super func ~str
	init: super func ~strWithLength

	
	clone: func -> This { 
		result := This new(size)
		memcpy(result data as Char*, data as Char *, size)
		result pos = pos
		result searchBuffer = (searchBuffer) ? searchBuffer clone() : null
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
		if (pos) pos += searchBuffer size // add searchterm size to pos on continued searches, otherwise we would find the last result again
		
		found : Bool		
		maxpos : Int = size - searchBuffer size // TODO use unsigned type with the size of SizeT instead of Int (32 bit type)
		
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
	
	// quickest possible replace algorithm, uses only 2 malloc's and 1 linear read as well as 1 linear write
	// "this" is the haystack, "what" the needle, "whit" the replacement
	replaceAll: func (what, whit : Buffer) -> This {
		if (what == null || what size == 0 || whit == null) return clone()
	
		initSearch(what);
		
		// we make a list of positions returned, maxed out to maximum possible capacity
		// so we dont loose cpu cycles for realloc
		// mem usage will only get slightly higher with really huge strings
		// but still far below what we're used to from java/.net
		l := ArrayList <SizeT> new (size / what size)
		while (find()) 	l add (pos)
		 
		if (l size() == 0) return clone()
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
	
}

