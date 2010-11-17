import HTTPRequest, io/[BufferWriter, BufferReader], text/StringTokenizer

// RestClient get("http://github.com/api/v2/json/user/show/pheuter") println()

RestClient: class {
  
  get: static func (request: HTTPRequest) -> String {
    request stream connect()
    request stream writer() write("GET "+request path+request requestParams toString()+" "+request requestHeader toString()+"\r\n")
    
    bw0 := BufferWriter new()
    bw0 write(request stream reader())
    html := bw0 buffer
    
    return html toString() split("\r\n\r\n") get(1)
  }
  
  get: static func ~asString (url: String) -> String { get(HTTPRequest new(url)) }
  
  post: static func (request: HTTPRequest) -> String {
    request stream connect()
    request stream writer() write("POST "+request path+request requestParams toString()+" "+request requestHeader toString()+"\r\n")
    
    bw0 := BufferWriter new()
    bw0 write(request stream reader())
    html := bw0 buffer
    
    return html toString() split("\r\n\r\n") get(1)
  }
  
  post: static func ~asString (url: String) -> String { post(HTTPRequest new(url)) }
  
}