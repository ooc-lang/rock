
import native/win32/types

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
    QueryPerformanceCounter: extern func (LargeInteger*)
    QueryPerformanceFrequency: extern func (LargeInteger*)
    Sleep: extern func (UInt)

    LocaleId: cover from LCID
    LOCALE_USER_DEFAULT: extern LocaleId
    GetTimeFormat: extern func (LocaleId, Long, SystemTime*, CString, CString, Int) -> Int
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
    _asctime: extern(asctime) func (TMStruct*) -> CString

    /**
        An `asctime` wrapper that copies the result to a new string. Otherwise,
        it would be overwritten in later calls.
        Also, the trailing newline character is stripped.
    */
    asctime: func (timePtr: TMStruct*) -> String {
        cStr := _asctime(timePtr)
        String new(cStr, cStr length() - 1)
    }
}

/* implementation */

Time: class {
    __time_millisec_base := static This runTime

    /**
        Returns the current date + time as a human-readable string without a trailing newline character.
    */
    dateTime: static func -> String {
	version (windows) {
	    length := GetTimeFormat(LOCALE_USER_DEFAULT, 0, null, null, null, 0)
	    buffer := gc_malloc(length + 1) as Char*
	    GetTimeFormat(LOCALE_USER_DEFAULT, 0, null, null, buffer, length)
	    return String new(buffer, length)
	}
	version (!windows) {
	    tm: TimeT
	    time(tm&)
	    return asctime(localtime(tm&))
	}
	return "<unsupported platform>"
    }

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
            version(windows) {
                // NOTE: this was previously using timeGetTime, but it's
                // a winmm.lib function and we can't afford the extra dep
                // I believe every computer that runs ooc programs on Win32
                // has a hardware high-performance counter, so it shouldn't be an issue
                counter, frequency: LargeInteger
                QueryPerformanceCounter(counter&)
                QueryPerformanceFrequency(frequency&)
                return ((counter quadPart * 1000) / frequency quadPart) - __time_millisec_base
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
     * @return the number of milliseconds spent executing 'action'
     */
    measure: static func (action: Func) -> UInt {
        t1 := runTime
        action()
        t2 := runTime
        t2 - t1
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
