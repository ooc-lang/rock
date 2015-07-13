/*stdint is not included by default*/
include stdint

assert: func<K,T>(a: K, T: Class){
    if(a class name != T name){
        Exception new("Mismatch! %s vs %s" format(a class name, T name)) throw()
    }
}

mytype : cover from Int64
mytype2 : cover from Float

a : Double = 2.

assert(a+1, Double)
assert(a+1., Double)
assert(a+1.f, Double)
assert(a+1l, Double)
assert(a+1ll, Double)
assert(1+a, Double)
assert(1.+a, Double)
assert(1.f+a, Double)
assert(1l+a, Double)
assert(1ll+a, Double)

b : LDouble = 2.

assert(b+1, LDouble)
assert(b+1., LDouble)
assert(b+1.f, LDouble)
assert(b+1l, LDouble)
assert(b+1ll, LDouble)
assert(1+b, LDouble)
assert(1.+b, LDouble)
assert(1.f+b, LDouble)
assert(1l+b, LDouble)
assert(1ll+b, LDouble)

c : Float = 2.

assert(c+1, Float)
assert(c+1.f, Float)
assert(c+1l, Float)
assert(c+1ll, Float)
assert(1+c, Float)
assert(1.f+c, Float)
assert(1l+c, Float)
assert(1ll+c, Float)

d : mytype = 2
assert(d+1, mytype)
assert(d+1.f, Float)
assert(d+1l, mytype)
assert(d+1ll, LLong)
assert(1+d, mytype)
assert(1.f+d, Float)
assert(1l+d, mytype)
assert(1ll+d, LLong)


e : mytype2 = 2.

assert(e+1, mytype2)
assert(e+1.f, mytype2)
assert(e+1l, mytype2)
assert(e+1ll, mytype2)
assert(1+e, mytype2)
assert(1.f+e, Float)
assert(1l+e, mytype2)
assert(1ll+e, mytype2)


f : LLong = 1

assert(f+1, LLong)
assert(f+1.f, Float)
assert(f+1l, LLong)
assert(f+1ll, LLong)
assert(1+f, LLong)
assert(1.f+f, Float)
assert(1l+f, LLong)
assert(1ll+f, LLong)

g : Long = 1

assert(g+1, Long)
assert(g+1.f, Float)
assert(g+1l, Long)
assert(g+1ll, LLong)
assert(1+g, Long)
assert(1.f+g, Float)
assert(1l+g, Long)
assert(1ll+g, LLong)

h : ULLong = 1

assert(h+1, ULLong)
assert(h+1.f, Float)
assert(h+1l, ULLong)
assert(h+1ll, ULLong)
assert(1+h, ULLong)
assert(1.f+h, Float)
assert(1l+h, ULLong)
assert(1ll+h, ULLong)

j : ULong = 1

assert(j+1, ULong)
assert(j+1.f, Float)
assert(j+1l, ULong)
assert(j+1ll, LLong)
assert(1+j, ULong)
assert(1.f+j, Float)
assert(1l+j, ULong)
assert(1ll+j, LLong)


i : Short = 1

assert(i+1, Int)
assert(i+1.f, Float)
assert(i+1l, Long)
assert(i+1ll, LLong)
assert(1+i, Int)
assert(1.f+i, Float)
assert(1l+i, Long)
assert(1ll+i, LLong)


k : Int8 = 1

assert(k+1, Int)
assert(k+1.f, Float)
assert(k+1l, Long)
assert(k+1ll, LLong)
assert(1+k, Int)
assert(1.f+k, Float)
assert(1l+k, Long)
assert(1ll+k, LLong)

/*
l : Char = 1

assert(l, Char)
assert(l+1, Int)
assert(l+1.f, Float)
assert(l+1l, Long)
assert(l+1ll, LLong)
assert(1+l, Int)
assert(1.f+l, Float)
assert(1l+l, Long)
assert(1ll+l, LLong)
assert('c'+l, Char)

m : UChar = 1

assert(m+1, Int)
assert(m+1.f, Float)
assert(m+1l, Long)
assert(m+1ll, LLong)
assert(1+m, Int)
assert(1.f+m, Float)
assert(1l+m, Long)
assert(1ll+m, LLong)
assert('c'+m, UChar)
*/

n : Int16 = 1

assert(n+1, Int)
assert(n+1.f, Float)
assert(n+1l, Long)
assert(n+1ll, LLong)
assert(1+n, Int)
assert(1.f+n, Float)
assert(1l+n, Long)
assert(1ll+n, LLong)

o : Int32 = 1

assert(o+1, Int32)
assert(o+1.f, Float)
assert(o+1l, Long)
assert(o+1ll, LLong)
assert(1+o, Int32)
assert(1.f+o, Float)
assert(1l+o, Long)
assert(1ll+o, LLong)

p : Int64 = 1

assert(p+1, Int64)
assert(p+1.f, Float)
assert(p+1l, Int64)
assert(p+1ll, LLong)
assert(1+p, Int64)
assert(1.f+p, Float)
assert(1l+p, Int64)
assert(1ll+p, LLong)

q : UInt64 = 1

assert(q+1, UInt64)
assert(q+1.f, Float)
assert(q+1l, UInt64)
assert(q+1ll, UInt64)
assert(1+q, UInt64)
assert(1.f+q, Float)
assert(1l+q, UInt64)
assert(1ll+q, UInt64)

r : UInt8 = 1

assert(r+1, Int)
assert(r+1.f, Float)
assert(r+1l, Long)
assert(r+1ll, LLong)
assert(1+r, Int)
assert(1.f+r, Float)
assert(1l+r, Long)
assert(1ll+r, LLong)

s : UInt16 = 1

assert(s+1, Int)
assert(s+1.f, Float)
assert(s+1l, Long)
assert(s+1ll, LLong)
assert(1+s, Int)
assert(1.f+s, Float)
assert(1l+s, Long)
assert(1ll+s, LLong)

t : UInt32 = 1

assert(t+1, UInt32)
assert(t+1.f, Float)
assert(t+1l, UInt32)
assert(t+1ll, LLong)
assert(1+t, UInt32)
assert(1.f+t, Float)
assert(1l+t, UInt32)
assert(1ll+t, LLong)

/* in many compiler, Long is larger than Int */
u : UInt = 1

assert(u+1, UInt)
assert(u+1.f, Float)
assert(u+1l, Long)
assert(u+1ll, LLong)
assert(1+u, UInt)
assert(1.f+u, Float)
assert(1l+u, Long)
assert(1ll+u, LLong)

