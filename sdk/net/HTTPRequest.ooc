import lang/Buffer, net/StreamSocket

HTTPRequest: class {
  host: String
  path: String
  port: Int
  stream: StreamSocket
  requestHeader: Buffer
  requestParams: Buffer
  params?: Bool
  
  init: func (url: String, =port) {
    if (url startsWith?("http://")) {
      tmp := url[7..(url length())] 
      host = tmp[0..(tmp indexOf('/'))]
      path = tmp[(tmp indexOf('/'))..(tmp length())]
    } else {
      host = url[0..(url indexOf('/'))]
      path = url[(url indexOf('/'))..(url length())]
    }
        
    stream = StreamSocket new(host,port)
    requestHeader = Buffer new()
    
    // Default header values
    addHeader("HTTP/1.1")
    addHeader("Host: "+host)
    addHeader("Connection: close")
    
    requestParams = Buffer new()
    params? = false 
  }
  
  init: func ~defaultPort(url: String) { init(url, 80) }
  
  addHeader: func (header: String) { requestHeader append(header) .append("\r\n") }
  
  addParam: func (key: String, val: String) {
    if (!params?) {
      params? = true
      requestParams append("?"+key+"="+val)
    } else requestParams append("&"+key+"="+val)
  }
 
}