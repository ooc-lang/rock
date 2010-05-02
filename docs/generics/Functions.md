Generic functions
=================

Tell me your size, I'll tell you which type you are
---------------------------------------------------

Generic functions are functions that take arguments that have generic types.

Generic types are types we don't know the size at compile-time.

We don't know their size at compile time, because they could be any type.

Because they could be any type, and thus any size (e.g. a 32bits int, 
a 64bits pointer, or a larger type such as a struct), we can't pass them
directly as an argument. Instead, we pass a pointer to them.

C allows pointers to pretty much anything. When, at runtime, we know
the type of the generic variable, we can cast the pointer and then dereference it.

Which allows thing like:

    print: func <T> (value: T) {
        if(T == Int) {
            printf("%d\n", value as Int)
        } else {
            printf("Unknown type %s\n", T name)
        }
    }
    
to work.

If we call print(42), it'll print "42", and if we call for example
print(3.14) it'll print "Unknown type Float"
    
There are several things going on here.

  - We declare a generic type, e.g. 'T'. It means that the real signature of the function is:
  
        print: func (T: Class, value: Pointer)
        
  - We compare T and Int. How it is possible? As pointed just above, 'T' is in fact
    a class. And Int is the class of an Int, too so we can just go ahead and compare them
    
  - We cast value to Int. How is it done in the C? Well, value is a void*, so we just
    cast it to int* and dereference it. We'd write it like this in ooc:
    
        (value as Int*)@
  
What about each?
----------------

If you've read all of the above, you now probably know why a naive each like this:

[1, 2, 3, 4] as ArrayList<Int> each(|x| x toString() println())

Won't work.

each() except a function whose signature is:

    func <T> (value: T)
    
ie whose *real* signature is:

    func (T: Class, value: Pointer)

And we pass it a function whose signature is:

    func (value: Int)
    
That simply doesn't work.

What needs to be done here, is we need to generate an intermediate function that does:

    func <T> (value: T) { otherFunction(value as Int) }
    
The 'value as Int' part is just a Cast AST node.
'Int' is a BaseType.

Constructing a generic function is just adding typeArgs to it. TypeArgs
are usually VariableAccesses.

