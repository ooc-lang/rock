
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

    timeGetTime: extern func -> UInt32
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
    __time_millisec_base := static This runTime
    
	/**
	    Returns the microseconds that have elapsed in the current minute.
	*/
	microtime: static func -> LLong {
		return microsec() as LLong + (sec() as LLong) * 1_000_000
	}
	
	/**
	    Returns the microseconds that have elapsed in the current second.
	*/
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
		return -1
	}
	
	/**
	    Gets the number of milliseconds elapsed since program start.
	*/
	runTime: static UInt {
	    get {
    	    t: ULLong
    	    version(windows) {
    	        // NOTE: timeGetTime only returns a 32-bit integer.  the upside is
    	        // that it's accurate to 1ms, but unfortunately rollover is very
    	        // possible
    	        timeGetTime() as UInt - __time_millisec_base
    	    }
            version(!windows) {
                tv : TimeVal
                gettimeofday(tv&, null)
                return ((tv tv_usec / 1000 + tv tv_sec * 1000) - __time_millisec_base) as UInt
    		}
    	    return -1
	    }
	}
	
	/**
	    Returns the seconds that have elapsed in the current minute.
	*/
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
		return -1
	}
	
	/**
	    Returns the minutes that have elapsed in the current hour.
	*/
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
		return -1
	}
	
	/**
	    Returns the hours that have elapsed in the current day.
	*/
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
		return -1
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
