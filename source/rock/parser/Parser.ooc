Parser_parse: extern proto func -> Int

Parser: cover {
    
    parse: static extern(Parser_parse) func (path: String) -> Int
    
}
