
main: func {
	"LLong: 1 compareTo 8? %d" format(1 as LLong compareTo(8 as LLong)) println()
	"LLong: 8 compareTo 1? %d" format(8 as LLong compareTo(1 as LLong)) println()
	"LLong: 8 compareTo 8? %d" format(8 as LLong compareTo(8 as LLong)) println()
	
	"" println()
	
	"1 compareTo 8? %d" format(1 compareTo(8)) println()
	"8 compareTo 1? %d" format(8 compareTo(1)) println()
	"8 compareTo 8? %d" format(8 compareTo(8)) println()
}