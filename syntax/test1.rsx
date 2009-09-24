import frontend/model/[IntLiteral]

-- Statement : Node

-- Expression : Statement

-- Literal : Expression

-- DecimalInt : Literal

value : DEC_INT

=> IntLiteral (value, IntFormat DEC)

-- Addition : Expression

left : %Expression
op: PLUS
right : %Expression

=> Add (left, right)

-- Line : Node 

statement : %Statement
endline: LINESEP

=> Line (statement)
