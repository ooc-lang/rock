StringReader: class extends BufferReader {
    init: func ~withString (string: String) {
        super(Buffer new(string))
    }
}
