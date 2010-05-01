rock tutorial
=============

nodes
-----

Everything is an AST node. Includes are nodes. Variable declarations are nodes.

tokens
------

Tokens are used to determine where a nodes come from (File, line number)
from the parsing phase.

When you create nodes from scratch you can use 'nullToken' which means
the node was created ex nihilo.

types
-----

BaseType are ArrayList, List, Pointer
FuncType is Func (T) -> K
PointerType is Int*, Char*
ReferenceType is Int@

creating types
--------------

    intType := BaseType new("Int", nullToken)

NB: It's a bad idea to use 'nullToken', it'll give strange error messages.
If you're manipulating the AST from existing nodes, you're probably better
off using the closest node's token.

creating a variable
-------------------

e.g. the code

    myvar: Int
    
is constructed with

    intType := BaseType new("Int", nullToken)
    vDecl := VariableDecl new(intType, "myvar", nullToken)
    
In this case it's probably better to use IntLiteral type though (you can
also use NullLiteral, etc.)

    vDecl := VariableDecl new(IntLiteral type, "myvar", nullToken)
    
creating literals
-----------------

    kalamazoo := 42
    
is constructed with

    vDecl := VariableDecl new(null, "kalamazoo", IntLiteral new(42, nullToken))
    
A null type for a VariableDecl will infer 


classes
-------

    Dog: class {}
    
is constructed with

    dogClass := ClassDecl new("Dog", nullToken)
    
You can add member variables, e.g.

    Dog: class {
        name: String
    }
    
With

    vDecl := VariableDecl new(StringLiteral type, "name", nullToken)
    dogClass addVariable(vDecl)


function calls
--------------

    exit()
    
Is created with

    FunctionCall new("exit", nullToken)
    
Also,

    exit(128)
    
Is created with

    call := FunctionCall new("exit", nullToken)
    call getArguments() add(IntLiteral new(128, nullToken))

member calls
------------

    msg := "Hi world"
    msg println()
    
Is created with

    vDecl := VariableDecl new(null, "msg", StringLiteral new("Hi world", nullToken), nullToken)
    vAcc := variableAccess new(vDecl, nullToken)
    fCall := FunctionCall new(vAcc, "println", nullToken)

variable accesses
-----------------

Above, we use a VariableAccess to call a method on a variable.

VariableAccesses can be created from different things.

Either you directly know the VariableDecl you wanna access and you can do

    VariableAccess new(vDecl, nullToken)
    
Or you just know its name and you want it resolved

    VariableAccess new("myVariable", nullToken)
    
You can even have a VariableAccess to a type

    VariableAccess new(IntLiteral type, nullToken)
    
Which is useful, for example, if you want to have a variable access
to "Int size". See below for member accesses


member accesses
---------------

They're like variable accesses, but with a non-null expr.

So to do for example

    Int size
    
We'd do

    intAccess := VariableAccess new(IntLiteral type, nullToken)
    sizeAccess := VariableAccess new(intAccess, "size", nullToken)

instanciating objects
---------------------

    dog := Dog new()
    
Is constructed like

    dogClass := VariableAccess new("Dog", nullToken)
    newCall := FunctionCall new(dogClass, "new", nullToken)
    dogDecl := VariableDecl new(null, "dog", newCall, nullToken)
    
    
function call arguments
-----------------------
    
    printf("Hai, world!\n")

Is constructed with

    call := FunctionCall new("printf", nullToken)
    arg1 := StringLiteral new("Hai, world!\n", nullToken)
    call getArguments() add(arg1)

resolving & the compilation process
-----------------------------------

at least once in the compilation process, resolve() is called
on every node.

how does it work?

The Tinkerer class organizes all Resolvers. There is one Resolver
per Module. The Tinkerer makes 'rounds' until all modules are fully
resolved, or until we've reached '-blowup' rounds.

Resolver simply calls resolve() on its module. Then Module calls
resolve() on its types, function declarations, etc. Every function
declaration calls resolve() on its arguments, its body, etc.

The resolve() method has two arguments: the Resolver corresponding
to the current module, and a Trail. The Trail is the hierarchy of
parent nodes.

That implies that if you have sub-nodes to resolve, you probably want
to push yourself on the trail before calling resolve on them, e.g.

    FunctionDecl: class extends Node {

        resolve: func (trail: Trail, res: Resolver) -> Response {

            trail push(this)
            body resolve(trail, res)
	    trail pop(this)

        }

    }

When debugging you can output the trail with trail toString() println().
It'll give something like:

    \_, Module rock/middle/tinker/Resolver
      \_, ClassDecl ResolverClass
        \_, Resolver.wholeAgain: func (node : Node, reason : String)
          \_, {if (Resolver.fatal && BuildParams.fatalError), if (Resolver.fatal && BuildParams.debugLoop), Resolver.wholeAgain = true}
            \_, if (Resolver.fatal && BuildParams.fatalError)
              \_, Resolver.fatal && BuildParams.fatalError

Apart from that, Trail is a subclass of Stack<Node> so you have
your pretty standard stack manipulation method, e.g. push, 
peek (get the node on top of the stack), pop(like peek but
also removes that node from the stack), but also get(), removeAt()
There's also peek(n) which allows you to retrieve the top-but-n
element of the trail.

E.g. peek() will give you the parent, peek(2) the grandparent, etc.

ast manipulation
----------------

Just like resolve() is implemented by every Node, replace() has to
be implemented too. It allows us to to AST manipulation.

Its definition is:

    replace: func (oldie, kiddo: Node) -> Bool

It replaces 'oldie' with 'kiddo' in the node, returning true in case
of success, or false if nothing could be replaced (most often because
you're trying to replace a node that doesn't exist)

In its most basic form, what you want to do is:

    // build otherNode (...)
    trail peek() replace(this, otherNode) // ask our parent to replace ourselves

But you probably want to do some error checking. See the next section
for an example.

errors, warnings, and other kinds of messages
---------------------------------------------

Tokens are at the heart of error reporting. Every node has one.
A token contains the Module to which the node belongs.

Tokens have three very useful method: printMessage, throwWarning,
throwError.

You should never abort the compilation process by calling
exit() or something like that. Just throw errors.

This allows command line options like "-allerrors" to work
(when -allerrors is set, compilation isn't aborted when 
an error is thrown)

Also, when you're trying to resolve things, it's probably better
to wait for the fatal (last) resolving round (e.g. check if 'res fatal' is true)

Throwing a simple error:

    // still not resolved and in the fatal round?
    if(ref == null && res fatal) {
        token throwError("No such variable %s" format(name))
    }

looping
-------

Often, we just can't resolve everything in one pass. In that case, you probably
want to 'wholeAgain'

    if(someNode getType() == null || !someNode getType() isResolved()) {
        // remember, 'res' is our Resolver
        res wholeAgain(this, "Need type of someNode!")
        return Responses OK
    }

wholeAgain marks the module as 'not resolved yet', and continues normally
the resolving process, so that some other nodes may be resolved before we loop.

Of course, between wholeAgain() and the next resolve() call, some other modules
may have been resolved further, which might help us - this is the whole point of
looping. This is also one of the main reasons you can declare anything in about any
order in ooc.

In some rare cases, you might want to return Responses LOOP

    trail peek(2) replace(trail peek(), newParent)
    // we replaced our parent, the trail is now messed up, we need to hard-loop
    return Responses LOOP

Using Responses LOOP should be reserved for extreme cases, because
it slows down compilation a fair bit. As a general rule, if you don't modify
the trail down your parent, you're fine.

In the future, we hope to implement a more event-based approach, because
both wholeAgain() and Responses LOOP imply lots of unnecessary node
exploration.













