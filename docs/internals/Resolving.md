resolving
=========

VariableAccess/FunctionCall/Type vs \*Decl
-----------------------------------------

Every VariableAccess, FunctionCall, and Type, has a 'ref' field
that corresponds to what it refers to.

When we get out of the parsing stage, almost every ref is null.
That's why we have resolve rounds.

During resolve rounds (which are orchestrated by tinker/Tinkerer
 and tinker/Resolver), the resolve() method is called on every node.
 
For more details read the 'resolving & the compilation process'
paragraph of Tutorial.md

A complete example
------------------

Point is - when a VariableAccess resolved, its ref is set to the
VariableDecl it refers to. For example:

    msg := "Hi, world" // line 1
    msg println()      // line 2
    
What happens here? It's parsed down to something like:

    VariableDecl(type=null, name="msg", expr=StringLiteral(value="Hi, world"))
    FunctionCall(expr=VariableAccess(name="msg"), name="println", args=[])

  1. On line 1, VariableDecl has a null type (because it's a decl-assign),
so it tries to resolve it from its 'expr'. Here, the expr is a StringLiteral,
which type is always 'String'.  Hence, msg's type is now 'String'

  2. On line 2, FunctionCall's expr is a VariableAccess to 'msg'. So it'll try
to resolve its expr before trying to resolve the call.

  3. So, the VariableAccess to 'msg' is resolved. In its trail, it has the FunctionCall,
then a Scope, and then the FunctionDecl we're into (probably 'main'). It calls
resolveCall(this) on each of these nodes

  4. When resolveCall(variableAccess) is called on the Scope, it looks for a VariableDecl
named 'msg', and.. bingo! there's one. Hence, it calls variableAccess suggest(variableDecl)

  5. in VariableAccess suggest(), we check that the VariableDecl is fit for our usage
(e.g. if we're a member access, check that it's a member variable declaration), and if
yes, we assign it to our ref.

  6. Back to our FunctionCall, now that our expr is resolved, we can use its type
to resolve the call to println(). In this case String's ref is a CoverDecl, which
contains the method 'println', so we can set the call's ref to that FunctionDecl.

