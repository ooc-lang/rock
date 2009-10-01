

varAccess ::= TokenRule NAME
access ::= (varAccess | assign)

assign ::= SequenceRule (expression, TokenRule ASSIGN, expression)

paren ::= SequenceRule (TokenRule OPEN_PAREN, expression, TokenRule CLOS_PAREN)

expression ::= (access, paren)



(a = b)

