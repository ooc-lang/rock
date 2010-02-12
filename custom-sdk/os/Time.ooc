
/* includes */

version(linux) {
    include unistd | (__USE_BSD), sys/time | (__USE_BSD), time | (__USE_BSD)
    //include unistd, sys/time, time
}
version(!linux) {
    include unistd, sys/time
}

version(windows) {
	include windows
}

/* covers & functions */

version(windows) {
	SystemTime: cover from SYSTEMTIME {
		wHour, wMinute, wSecond, wMilliseconds : extern UShort
	}

	GetLocalTime: extern func (SystemTime*)
	Sleep: extern func (UInt)
}

version(!windows) {
	TimeT: cover from time_t
	TimeZone: cover from struct timezone
	TMStruct: cover from struct tm {
		tm_sec, tm_min, tm_hour, tm_mday, tm_mon, tm_year, tm_wday, tm_yday, tm_isdst : extern Int
	}
	TimeVal: cover from struct timeval {
		tv_sec: extern TimeT
		tv_usec: extern Int
	}

	time: extern proto func (TimeT*) -> TimeT
	localtime: extern func (TimeT*) -> TMStruct*
	gettimeofday: extern func (TimeVal*, TimeZone*) -> Int
	usleep: extern func (UInt)
}

/* implementation */

Time: class {
	
	microtime: static func -> LLong {
		return microsec() as LLong + (sec() as LLong) * 1_000_000
	}
	
	microsec: static func -> UInt {
		version(windows) {
			st: SystemTime
			GetLocalTime(st&)
			return st wMilliseconds * 1000
		}
		version(!windows) {
			tv : TimeVal
			gettimeofday(tv&, null)
			return tv tv_usec
		}
	}
	
	sec: static func -> UInt {
		version(windows) {
			st: SystemTime
			GetLocalTime(st&)
			return st wSecond
		}
		version(!windows) {
			tt := time(null)
			val := localtime(tt&)
			return val@ tm_sec
		}
	}
	
	min: static func -> UInt {
		version(windows) {
			st: SystemTime
			GetLocalTime(st&)
			return st wMinute
		}
		version(!windows) {
			tt := time(null)
			val := localtime(tt&)
			return val@ tm_min
		}
	}
	
	hour: static func -> UInt {
		version(windows) {
			st: SystemTime
			GetLocalTime(st&)
			return st wHour
		}
		version(!windows) {
			tt := time(null)
			val := localtime(tt&)
			return val@ tm_hour
		}
	}
	
	sleepSec: static func (duration: Float) {
		sleepMicro(duration * 1_000_000)
	}

	sleepMilli: static func (duration: UInt) {
		sleepMicro(duration * 1_000)
	}

	sleepMicro: static func (duration: UInt) {
		version(windows) {
			Sleep(duration / 1_000)
		}
		version(!windows) {
			usleep(duration)
		}
	}

}
