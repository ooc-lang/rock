TokenType: class {
	
	CLASS_KW = 1 : static const Octet // class keyword
	COVER_KW = 2 : static const Octet // cover keyword
	FUNC_KW = 3 : static const Octet // func keyword
	ABSTRACT_KW = 4 : static const Octet // abstract keyword
	EXTENDS_KW = 5 : static const Octet // from keyword
	FROM_KW = 6 : static const Octet // over keyword
	
	CONST_KW = 10 : static const Octet // const keyword
	FINAL_KW = 11 : static const Octet // const keyword
	STATIC_KW = 12 : static const Octet // static keyword
	
	INCLUDE_KW = 13 : static const Octet // include keyword
	IMPORT_KW = 14 : static const Octet // import keyword
	USE_KW = 15 : static const Octet // use keyword
	EXTERN_KW = 16 : static const Octet // extern keyword
	INLINE_KW = 17 : static const Octet // extern keyword
	PROTO_KW = 18 : static const Octet // proto keyword
	
	BREAK_KW = 19 : static const Octet // break keyword
	CONTINUE_KW = 20 : static const Octet // continue keyword
	FALLTHR_KW = 21 : static const Octet // fallthrough keyword
	
	OPERATOR_KW = 22 : static const Octet // operator keyword
	
	IF_KW = 23 : static const Octet
	ELSE_KW = 24 : static const Octet
	FOR_KW = 25 : static const Octet
	WHILE_KW = 26 : static const Octet
	DO_KW = 27 : static const Octet
	SWITCH_KW = 28 : static const Octet
	CASE_KW = 29 : static const Octet
	
	AS_KW = 30 : static const Octet
	IN_KW = 31 : static const Octet
	
	VERSION_KW = 32 : static const Octet // version keyword
	
	RETURN_KW = 33 : static const Octet
	
	TRUE_KW = 34 : static const Octet
	FALSE_KW = 35 : static const Octet
	NULL_KW = 36 : static const Octet
	
	OOCDOC = 37 : static const Octet // oodoc comment, e.g. /** blah */
	
	NAME = 38 : static const Octet // mostly a Java identifier

	BACKSLASH = 39 : static const Octet // \
	DOUBLE_BACKSLASH = 40 : static const Octet // \\
	AT = 41 : static const Octet // @
	HASH = 42 : static const Octet // #
	TILDE = 43 : static const Octet // ~
	COMMA = 44 : static const Octet //  : static const Octet
	DOT = 45 : static const Octet // .
	DOUBLE_DOT = 46 : static const Octet // ..
	TRIPLE_DOT = 47 : static const Octet // ...
	ARROW = 48 : static const Octet // ->
	COLON = 49 : static const Octet // :
	LINESEP = 50 : static const Octet //  ';' or newline
	
	PLUS = 51 : static const Octet // +
	PLUS_ASSIGN = 52 : static const Octet // +=
	MINUS = 53 : static const Octet // -
	MINUS_ASSIGN = 54 : static const Octet // -=
	STAR = 55 : static const Octet // *
	STAR_ASSIGN = 56 : static const Octet // *=
	SLASH = 57 : static const Octet // /
	SLASH_ASSIGN = 58 : static const Octet // /=
	
	PERCENT = 59 : static const Octet // %
	BANG = 60 : static const Octet // !
	NOT_EQUALS = 61 : static const Octet // !=
	QUEST = 62 : static const Octet // ?
	
	GREATERTHAN = 63 : static const Octet // >
	LESSTHAN = 64 : static const Octet // <
	GREATERTHAN_EQUALS = 65 : static const Octet // >=
	LESSTHAN_EQUALS = 66 : static const Octet // <=
	ASSIGN = 67 : static const Octet // =
	DECL_ASSIGN = 68 : static const Octet // :=
	EQUALS = 69 : static const Octet // ==
	
	DOUBLE_AMPERSAND = 70 : static const Octet // && (logical and)
	DOUBLE_PIPE = 71 : static const Octet // || (et non pas double pipe..)
	
	AMPERSAND = 72 : static const Octet // & (binary and)
	PIPE = 73 : static const Octet // | (binary or)
	
	CHAR_LIT = 74 : static const Octet // 'c'
	STRING_LIT = 75 : static const Octet // "blah\n"
	
	DEC_INT = 76 : static const Octet // 234
	HEX_INT = 77 : static const Octet // 0xdeadbeef007
	OCT_INT = 78 : static const Octet // 0c777
	BIN_INT = 79 : static const Octet // 0b1011
	DEC_FLOAT = 80 : static const Octet // 3.14
	
	OPEN_PAREN = 81 : static const Octet // (
	CLOS_PAREN = 82 : static const Octet // )
	
	OPEN_BRACK = 83 : static const Octet // {
	CLOS_BRACK = 84 : static const Octet // }
	
	OPEN_SQUAR = 85 : static const Octet // [
	CLOS_SQUAR = 86 : static const Octet // ]
	
	UNSIGNED = 87 : static const Octet
	SIGNED = 88 : static const Octet
	LONG = 89 : static const Octet
	STRUCT = 90 : static const Octet
	UNION = 91 : static const Octet
	
	BINARY_AND = 92 : static const Octet //  &
	CARET = 93 : static const Octet // ^
	
	strings : static String*
	
}

loadStringsLit: func {
	
	MAX_TOKEN := 93

	stringsLit := [
		"<no token>",
		"class",
		"cover",
		"func",
		"abstract",
		"extends",
		"from",
		"this",
		"super",
		"new",
		
		"const",
		"final",
		"static",
		
		"include",
		"import",
		"use",
		"extern",
		"inline",
		"proto",
		
		"break",
		"continue",
		"fallthrough",
		
		"operator",
		
		"if",
		"else",
		"for",
		"while",
		"do",
		"switch",
		"case",
		
		"as",
		"in",
		
		"version",
		"return",
		
		"true",
		"false",
		"null",
		
		"oocdoc",
		
		"name",
		
		"\\",
		"\\\\",
		"@",
		"#",
		"~",
		",",
		".",
		"..",
		"...",
		"->",
		":",
		";",
		
		"+",
		"+=",
		"-",
		"-=",
		"*",
		"*=",
		"/",
		"/=",
		
		"%",
		"!",
		"!=",
		"?",
		
		">",
		"<",
		">=",
		"<=",
		"=",
		":=",
		"==",
		
		"&&",
		"||",
		
		"&",
		"|",
		
		"CharLiteral",
		"StringLiteral",
		
		"Decimal",
		"Hexadecimal",
		"Octal",
		"Binary",
		"DecimalFloat",
		
		"(",
		")",
		"{",
		"}",
		"[",
		"]",
		
		"unsigned",
		"signed",
		"long",
		"struct",
		"union",
		
		" &",
		"^",
		"^="
	] as String*

	TokenType strings = gc_malloc(MAX_TOKEN * Pointer size)
	memcpy(TokenType strings, stringsLit, MAX_TOKEN * Pointer size)

}

loadStringsLit()
