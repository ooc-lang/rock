import os/Time

main: func {

	"seconds = " print()
	seconds := stdin readLine() toInt()

	printTime()

	"go!" println()
	while(seconds) {
		(seconds + " seconds left.") println()
		seconds -= 1
		Time sleepSec(1) // sleep 1 second
	}
	"time's up!" println()
	
	printTime()

}

printTime: func {

	"%02d:%02d:%02d" format(Time hour(), Time min(), Time sec()) println()

}
