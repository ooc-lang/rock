import BufferReader

StringReader: class extends BufferReader {
    string: String

    init: func ~withString (=string) {
        super(string _buffer)
    }
}
