import text/Buffer /* for String replace ~string */

String: class {

    buffer: Buffer


}


operator implicit as (s: String) -> Char* {
    s buffer data
}

operator implicit as (c: Char*) -> String {
    return c ? String new (c, strlen(c)) : null
}

operator == (str1: String, str2: String) -> Bool {
    return str1 equals?(str2)
}

operator != (str1: String, str2: String) -> Bool {
    return !str1 equals?(str2)
}

operator [] (string: String, index: SizeT) -> Char {
    string charAt(index)
}

operator []= (string: String, index: SizeT, value: Char) {
    if(index < 0 || index > string length()) {
        Exception new(String, "Writing to a String out of bounds index = %d, length = %d!" format(index, string length())) throw()
    }
    (string data + index)@ = value
}

operator [] (string: String, range: Range) -> String {
    string substring(range min, range max)
}

operator * (str: String, count: Int) -> String {
    return str times(count)
}

operator + (left, right: String) -> String {
    return left append(right)
}

operator + (left: LLong, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: LLong) -> String {
    left + right toString()
}

operator + (left: Int, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: Int) -> String {
    left + right toString()
}

operator + (left: Bool, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: Bool) -> String {
    left + right toString()
}

operator + (left: Double, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: Double) -> String {
    left + right toString()
}

operator + (left: String, right: Char) -> String {
    left append(right)
}

operator + (left: Char, right: String) -> String {
    right prepend(left)
}

// lame static function to be called by int main, so i dont have to metaprogram it
import structs/ArrayList

strArrayListFromCString: func (argc: Int, argv: Char**) -> ArrayList<String> {
    result := ArrayList<String> new ()
    for (i in 0..argc) {
        s := String new ((argv[i]) as CString, (argv[i]) as CString length())
        result add( s )
    }
    result
}