Test: class {

    new: static func -> Test { null }
    
}

operator [] (first: Test, second: Int) { "[] works" println() }
operator + (first, second: Test) { "+ works" println() }
operator - (first, second: Test) { "- works" println() }
operator * (first, second: Test) { "* works" println() }
operator / (first, second: Test) { "/ works" println() }
operator << (first, second: Test) { "<< works" println() }
operator >> (first, second: Test) { ">> works" println() }
operator ^ (first, second: Test) { "^ works" println() }
operator & (first, second: Test) { "& works" println() }
operator | (first, second: Test) { "| works" println() }

operator []= (first: Test, second: Int, third: Test) { "[]= works" println() }
operator += (first, second: Test) { "+= works" println() }
operator -= (first, second: Test) { "-= works" println() }
operator *= (first, second: Test) { "*= works" println() }
operator /= (first, second: Test) { "/= works" println() }
operator <<= (first, second: Test) { "<<= works" println() }
operator >>= (first, second: Test) { ">>= works" println() }
operator ^= (first, second: Test) { "^= works" println() }
operator &= (first, second: Test) { "&= works" println() }
operator |= (first, second: Test) { "|= works" println() }

operator && (first, second: Test) { "&& works" println() }
operator || (first, second: Test) { "|| works" println() }
operator % (first, second: Test) { "% works" println() }
operator = (first, second: Test) { "= works" println() }
operator == (first, second: Test) -> Bool { "== works" println(); true }
operator <= (first, second: Test) -> Bool { "<= works" println(); true }
operator >= (first, second: Test) -> Bool {	">= works" println(); true }
operator != (first, second: Test) -> Bool { "!= works" println(); true }
operator ! (first: Test) -> Bool { "! works" println(); true }
operator < (first, second: Test) -> Bool { "< works" println(); true }
operator > (first, second: Test) -> Bool { "> works" println(); true }
operator ~ (first: Test) -> Bool { "~ works" println(); true }
operator as (first: Test) -> String { "as works" println(); "Test!" }

main: func {
    
	one := Test new()
	two := Test new()
    
    one[123]
	one + two
	one - two
	one * two
	one / two
    one << two
    one >> two
    one ^ two
    one & two
    one | two
    
    one[123] = two
	one += two
	one -= two
	one *= two
	one /= two
    one <<= two
    one >>= two
    one ^= two
    one &= two
    one |= two
    
    one && two
    one || two
    one % two
    one = two
    one == two
    one >= two
	one <= two
	one != two
    !one
	one > two
    one < two
    ~one
    s1 := one as String
    
    a, b, c : Int

    c = a + b
    c = a - b
    c = a * b
    c = a / b
    c = a >> b
    c = a << b
    c = a ^ b
    c = a & b
    c = a | b
    
    a += b
    a -= b
    a *= b
    a /= b
    a <<= b
    a >>= b
    a ^= b
    a &= b
    a |= b
    
    c = !a
    c = a > b
    c = a < b
    c = ~a
    s2 := a as String
	
}

