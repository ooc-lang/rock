import text/Base64

/* encoding */

// from a string
random := "\xe0\x04\x16\xa5\x35\x43\xe4\x47\xe9\x2f\x1f\x7e\xf6\xf1\x78\x63\xe5\xe0\xd1\xcc\x7a\x3b\xf9"
assert(Base64 encode(random) == "4AQWpTVD5EfpLx9+9vF4Y+Xg0cx6O/k=")
assert(Base64 encode(random) != "Knorz")

// from an array
// TODO: It doesn't work with literals.
//someArray := [0x00, 0x33, 0xfe, 0xde, 0xad, 0xbe, 0xef, 0x03] as Octet[]
someArray := Octet[8] new()
someArray[0] = 0x00
someArray[1] = 0x33
someArray[2] = 0xfe
someArray[3] = 0xde
someArray[4] = 0xad
someArray[5] = 0xbe
someArray[6] = 0xef
someArray[7] = 0x03
assert(Base64 encode(someArray) == "ADP+3q2+7wM=")

// from a memory chunk
someData := gc_malloc(Octet size * 4) as Octet*
someData[0] = 0x55
someData[1] = 0xfa
someData[2] = 0xaf
someData[3] = 0xde
assert(Base64 encode(someData, 4) == "Vfqv3g==")

// test the padding
oneOctet := "\x00\x00\x00\x01"
assert(Base64 encode(oneOctet) == "AAAAAQ==")

twoOctets := "\x00\x00\x00\x01\x02"
assert(Base64 encode(twoOctets) == "AAAAAQI=")

threeOctets := "\x00\x00\x00\x01\x02\x03"
assert(Base64 encode(threeOctets) == "AAAAAQID")

/* decoding */

assert(Base64 decode("") length == 0)

assertEquals: func ~arrays (a: Octet[], b: Octet[]) {
   assert(a length == b length)
    for(i in 0..a length) {
        assert(a[i] == b[i])
    }
}

randomOctets := Octet[13] new()
randomOctets[0] = 60
randomOctets[1] = 8
randomOctets[2] = 128
randomOctets[3] = 239
randomOctets[4] = 142
randomOctets[5] = 41
randomOctets[6] = 66
randomOctets[7] = 23
randomOctets[8] = 208
randomOctets[9] = 88
randomOctets[10] = 32
randomOctets[11] = 0
randomOctets[12] = 144
assertEquals(Base64 decode("PAiA744pQhfQWCAAkA=="), randomOctets)

// test the padding

makeAString: func (octets: Octet[]) -> String {
    String new(octets data, octets length)
}
assert(makeAString(Base64 decode("AAAAAQ==")) == "\x00\x00\x00\x01")
assert(makeAString(Base64 decode("AAAAAQI=")) == "\x00\x00\x00\x01\x02")
assert(makeAString(Base64 decode("AAAAAQID")) == "\x00\x00\x00\x01\x02\x03")

// test errors

assertRaises: func (exception: Class, code: Func) {
    try {
        code()
    } catch(e: Exception) {
        assert(e class == exception)
    }
}

assertRaises(Base64Error, || Base64 decode("."))
assertRaises(Base64Error, || Base64 decode("abcdefghi==="))
assertRaises(Base64Error, || Base64 decode("A[[["))

makeAString(Base64 decode("QWxsIGlzIGdvb2Qu")) println()
