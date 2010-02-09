
main: func {
    
    i := 0
    
    // FIXME: it should work without parenthesis...
    
    s: String = gc_malloc(20)
    (s as Char*)[i] = 'c' ; i += 1
     s as Char* [i] = 'a' ; i += 1
     s as Char* [i] = 'c' ; i += 1
     s as Char* [i] = 'o' ; i += 1
     s as Char* [i] = 'u' ; i += 1
     s as Char* [i] = '\n'; i += 1
    
}

