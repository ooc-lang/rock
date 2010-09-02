import BufferReader

StringReader: class extends BufferReader {
    init: func ~withString (string: String) {
        super(string _buffer)
    }
}
