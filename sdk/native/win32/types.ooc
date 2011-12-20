/*
 * Win32 type covers
 *
 * @author Amos Wenger, aka nddrylliog
 */

version(windows) {

    include windows

    LocaleId: cover from LCID

    /*
     * File handle
     */
    Handle: cover from HANDLE
    INVALID_HANDLE_VALUE: extern Handle

    /*
     * Large integers
     */
    LargeInteger: cover from LARGE_INTEGER {
        lowPart : extern(LowPart)  Long
        highPart: extern(HighPart) Long
        quadPart: extern(QuadPart) LLong
    }

    /*
     * Unsigned large integers
     */
    ULargeInteger: cover from ULARGE_INTEGER {
        lowPart : extern(LowPart)  Long
        highPart: extern(HighPart) Long
        quadPart: extern(QuadPart) LLong
    }

    toLLong: func ~twoPartsLargeInteger (lowPart, highPart: Long) -> LLong {
        li: LargeInteger
        li lowPart  = lowPart
        li highPart = highPart
        return li quadPart
    }

    toULLong: func ~twoPartsLargeInteger (lowPart, highPart: Long) -> ULLong {
        li: ULargeInteger
        li lowPart  = lowPart
        li highPart = highPart
        return li quadPart
    }

    /*
     * FILETIME is, in fact, an Int64 that stores the number of
     * 100-nanoseconds intervals from January 1st, 1601 (according to the MSDN)
     */
    FileTime: cover from FILETIME {
        lowDateTime:    extern(dwLowDateTime)  Long // DWORD
        highDateTime:   extern(dwHighDateTime) Long // DWORD
    }

    /*
     * source: http://frenk.wordpress.com/2009/12/14/convert-filetime-to-unix-timestamp/
     * thanks, Francesco De Vittori from Lugano, Switzerland!
     */
    toTimestamp: func ~fromFiletime (fileTime: FileTime) -> Long {
        // takes the last modified date
        date, adjust: LargeInteger
        date lowPart  = fileTime lowDateTime
        date highPart = fileTime highDateTime

        // 100-nanoseconds = milliseconds * 10000
        adjust quadPart = 11644473600000 * 10000;

        // removes the diff between 1970 and 1601
        date quadPart -= adjust quadPart

        // converts back from 100-nanoseconds to seconds
        return date quadPart / 10000000;
    }

}
