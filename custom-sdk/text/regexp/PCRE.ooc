import text/regexp/RegexpBackend
use text/regexp/pcre

Pcre: cover from pcre*
pcre_compile: extern func (String, Int, const Char**, Int*, Pointer) -> Pcre
pcre_exec: extern func(Pcre, Pointer, String, Int, Int, Int, Int*, Int) -> Int
pcre_free: extern func(Pointer)

PCRE_DEBUG : Bool = false

PCRE: class extends RegexpBackend {
    CASELESS : extern(PCRE_CASELESS) static const Int
    
    error: String
    errorNum: Int
    re: Pcre
    
    __destroy__: func {
        if(PCRE_DEBUG) {
            printf("^")
        }
        pcre_free(re)
    }
    
    setPattern: func(pattern: String, options: Int) {
        this pattern = pattern
        
        re = pcre_compile(pattern, options, error& as const Char**, errorNum&, null)
        if (! re)
            printf("PCRE compilation failed at expression offset %d: %s\n", errorNum, error)
    }
    
    getName: func -> String { "PCRE" }
    
    matches: func(haystack: String) -> Bool { matches(haystack, 0) }
    
    matches: func~withOptions(haystack: String, options: Int) -> Bool { 
        // offsets := gc_malloc(10 * sizeof(Int)) as Int*
        return pcre_exec(re, null, haystack, haystack length(), 0, options, null, 0) >= 0
    }
}
