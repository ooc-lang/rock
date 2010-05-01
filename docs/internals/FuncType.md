function pointers
=================

syntax
------

C's syntax for function pointers is downright horrible.

    void (*(*f())(void (*)(void)))(void);
    
That would be simply written in ooc as

     f: func -> Func(Func) -> Func
     
ie. a function that returns a pointer to a function taking a function
and returning another function.

The difference between

    f: func
    
and

    f: Func
    
Is that the first defines an empty function, the latter defines
a pointer to a function. Apart from that, the syntax is pretty similar, ie.
let's say you have a 

    f: func (a, b: Int) -> Int
    
its type is

    Func (Int, Int) -> Int
    
Generic type arguments are also legal, e.g.

    print: func <K> (k: K)
    
which type is

    Func <K> (K)
    
You can have variadic functions too, e.g.

    print: func (fmt: String, ...) -> Int
    
which type is

    Func (String, ...)
    
AST
---

'Func' declarations result in a FuncType.

For the following declaration:

    Func <A, B> (C, D) -> E
    
A, B are its 'typeArgs' (of type VariableAccess)

C, D are its 'argTypes' (of type Type)

E is its 'returnType' (of type Type)


C typedefs
----------

In j/ooc we used to write the C syntax for function pointers in the generated
C code. But that was awful.

So now we just add typedefs like that:

    #ifndef __FUNC___Int_Int_Int__DEFINE
    #define __FUNC___Int_Int_Int__DEFINE

    typedef lang_types__Int (*__FUNC___Int_Int_Int)(lang_types__Int, lang_types__Int);

    #endif

The name '__FUNC___Int_Int_Int' is obtained via FuncType's toMangledString() method
