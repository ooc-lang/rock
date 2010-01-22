Test: class {

    new: static func -> Test { null }
    
}

operator [] (first: Test, second: Int) { println("[] works") }
operator + (first, second: Test) { println("+ works") }
operator - (first, second: Test) { println("- works") }
operator * (first, second: Test) { println("* works") }
operator / (first, second: Test) { println("/ works") }
operator << (first, second: Test) { println("<< works") }
operator >> (first, second: Test) { println(">> works") }
operator ^ (first, second: Test) { println("^ works") }
operator & (first, second: Test) { println("& works") }
operator | (first, second: Test) { println("| works") }

operator []= (first: Test, second: Int, third: Test) { println("[]= works") }
operator += (first, second: Test) { println("+= works") }
operator -= (first, second: Test) { println("-= works") }
operator *= (first, second: Test) { println("*= works") }
operator /= (first, second: Test) { println("/= works") }
operator <<= (first, second: Test) { println("<<= works") }
operator >>= (first, second: Test) { println(">>= works") }
operator ^= (first, second: Test) { println("^= works") }
operator &= (first, second: Test) { println("&= works") }
operator |= (first, second: Test) { println("|= works") }

operator && (first, second: Test) { println("&& works") }
operator || (first, second: Test) { println("|| works") }
operator % (first, second: Test) { println("% works") }
operator = (first, second: Test) { println("= works") }
operator == (first, second: Test) -> Bool { println("== works"); true }
operator <= (first, second: Test) -> Bool { println("<= works"); true }
operator >= (first, second: Test) -> Bool {	println(">= works"); true }
operator != (first, second: Test) -> Bool { println("!= works"); true }
operator ! (first: Test) -> Bool { println("! works"); true }
operator < (first, second: Test) -> Bool { println("< works"); true }
operator > (first, second: Test) -> Bool { println("> works"); true }
operator ~ (first: Test) -> Bool { println("~ works"); true }
operator as (first: Test) -> String { println("as works") }

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

