
version(windows) {

    import native/win32/types

    include windows

    GetLastError: extern func -> Int

    ERROR_HANDLE_EOF: extern Int

    FormatMessage: extern func(dwFlags: DWORD, lpSource: Pointer, dwMessageId: DWORD, dwLanguageId: DWORD,
        lpBuffer: LPTSTR, nSize: DWORD, Arguments: VaList*) -> DWORD

    FORMAT_MESSAGE_FROM_SYSTEM: extern Long
    FORMAT_MESSAGE_IGNORE_INSERTS: extern Long
    FORMAT_MESSAGE_ARGUMENT_ARRAY: extern Long

    GetWindowsErrorMessage: func (err: DWORD) -> String {
        BUF_SIZE := 256
        buf := Buffer new(BUF_SIZE)
        len: SSizeT = FormatMessage(
            FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS | FORMAT_MESSAGE_ARGUMENT_ARRAY,
            null,
            err,
            0,
            buf data as CString,
            BUF_SIZE,
            null
        )
        buf setLength(len)

        // rip away trailing CR LF TAB SPACES etc.
        while ((len > 0) && (buf[len - 1] as Octet < 32)) len -= 1
        buf setLength(len)
        buf toString()
    }

    WindowsException: class extends Exception {
      init: func (.origin, err: Long) {
        super(origin, GetWindowsErrorMessage(err))
      }

      init: func ~withMsg (.origin, err: Long, message: String) {
        super(origin, "%s: %s" format(message, GetWindowsErrorMessage(err)))
      }
    }

}
