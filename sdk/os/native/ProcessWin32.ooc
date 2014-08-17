import structs/[HashMap, ArrayList]
import ../Process, PipeWin32
import native/win32/[types, errors]

version(windows) {

include windows

/**
 * Process implementation for Win32
 */
ProcessWin32: class extends Process {

    si: StartupInfo
    pi: ProcessInformation

    cmdLine: String = ""

    init: func ~win32 (=args) {
        sb := Buffer new()
        for(arg in args) {
            //sb append('"'). append(arg). append("\" ")
            sb append(arg). append(' ')
        }
        cmdLine = sb toString()

        ZeroMemory(si&, StartupInfo size)
        si structSize = StartupInfo size
        ZeroMemory(pi&, ProcessInformation size)
    }

    _wait: func (duration: Long) -> Int {
        // Wait until child process exits.
        status := WaitForSingleObject(pi process, duration)

        if (status != WAIT_OBJECT_0) return -1

        exitCode: ULong
        GetExitCodeProcess(pi process, exitCode&)

        CloseHandle(pi thread)
        CloseHandle(pi process)
        exitCode
    }

    /**
     * Wait for the process to end. Bad things will happen
     * if you haven't called `executeNoWait` before.
     */
    wait: func -> Int {
        _wait(INFINITE)
    }

    waitNoHang: func -> Int {
        _wait(0)
    }

    /**
       Execute the process without waiting for it to end.
       You have to call `wait` manually.
    */
    executeNoWait: func -> Long {
        if (stdIn != null || stdOut != null || stdErr != null) {
            if(stdIn != null) {
                si stdInput  = stdIn as PipeWin32 readFD
                SetHandleInformation(stdOut as PipeWin32 writeFD, HANDLE_FLAG_INHERIT, 0)
            }
            if(stdOut != null) {
                si stdOutput = stdOut as PipeWin32 writeFD
                SetHandleInformation(stdOut as PipeWin32 readFD, HANDLE_FLAG_INHERIT, 0)
            }
            if(stdErr != null) {
                si stdError  = stdErr as PipeWin32 writeFD
                SetHandleInformation(stdErr as PipeWin32 readFD, HANDLE_FLAG_INHERIT, 0)
            }
            si flags |= StartFlags UseStdHandles
        }

        envString := buildEnvironment()

        // Reference: http://msdn.microsoft.com/en-us/library/ms682512%28VS.85%29.aspx
        // Start the child process.
        if(!CreateProcess(
            null,        // No module name (use command line)
            cmdLine toCString(), // Command line
            null,        // Process handle not inheritable
            null,        // Thread handle not inheritable
            true,        // Set handle inheritance to true
            0,           // No creation flags
            envString,   // Use parent's environment block
            cwd ? cwd toCString() : null, // Use custom cwd if we have one
            si&,         // Pointer to STARTUPINFO structure
            pi&          // Pointer to PROCESS_INFORMATION structure
        )) {
            err := GetLastError()
            ProcessException new(This, "CreateProcess failed (error %d: %s).\n Command Line:\n %s" format(
                err,
                GetWindowsErrorMessage(err),
                cmdLine
            )) throw()
            return -1
        }

        if(stdIn != null) {
            stdIn close('r')
        }

        if(stdOut != null) {
            stdOut close('w')
        }
        if(stdErr != null) {
            stdErr close('w')
        }
        
        this pid = pi pid
        return pi pid
    }

    buildEnvironment: func -> Char* {
        if (env == null) {
            return null
        }

        envLength := 1
        env each(|k, v|
            envLength += k size
            envLength += v size
            envLength += 2 // one for the =, one for the \0
        )

        envString := gc_malloc(envLength) as Char*
        index := 0
        for (k in env getKeys()) {
            v := env get(k)

            memcpy(envString + index, k toCString(), k size)
            index += k size

            envString[index] = '='
            index += 1

            memcpy(envString + index, v toCString(), v size)
            index += v size

            envString[index] = '\0'
            index += 1
        }

        envString[index] = '\0'
        envString
    }

    terminate: func {
        // TODO!
        "please implement me! ProcessWin32 terminate" println()
    }

    kill: func {
        // TODO!
        "please implement me! ProcessWin32 kill" println()
    }
}

// extern functions
ZeroMemory: extern func (Pointer, SizeT)
CreateProcess: extern func (CString, CString, Pointer, Pointer, 
    Bool, Long, Pointer, CString, Pointer, Pointer) -> Bool
WaitForSingleObject: extern func (Handle, Long) -> Int
GetExitCodeProcess: extern func (Handle, ULong*) -> Int
CloseHandle: extern func (Handle)
SetHandleInformation: extern func (Handle, Long, Long) -> Bool

HANDLE_FLAG_INHERIT: extern Long
HANDLE_FLAG_PROTECT_FROM_CLOSE: extern Long

WAIT_ABANDONED, WAIT_OBJECT_0, WAIT_TIMEOUT, WAIT_FAILED: extern Int

// covers
StartupInfo: cover from STARTUPINFO {
    structSize: extern(cb) Long
    reserved: extern(lpReserved) CString*
    desktop:  extern(lpDesktop) CString*
    title:    extern(lpTitle) CString*
    x: extern(dwX) Long
    y: extern(dwY) Long
    xSize: extern(dwXSize) Long
    ySize: extern(dwYSize) Long
    xCountChars: extern(dwXCountChars) Long
    yCountChars: extern(dwYCountChars) Long
    flags: extern(dwFlags) Long
    showWindow: extern(wShowWindow) Int
    cbReserved2: extern Int
    lpReserved2: extern Char* // LPBYTE
    stdInput : extern(hStdInput)  Handle
    stdOutput: extern(hStdOutput) Handle
    stdError : extern(hStdError)  Handle
}

StartFlags: cover {
    ForceOnFeedback : extern(STARTF_FORCEONFEEDBACK) static Long
    ForceOffFeedback: extern(STARTF_FORCEOFFFEEDBACK) static Long
    PreventPinning  : extern(STARTF_PREVENTPINNING) static Long
    RunFullScreen   : extern(STARTF_RUNFULLSCREEN) static Long
    TitleIsAppID    : extern(STARTF_TITLEISAPPID) static Long
    TitleIsLinkName : extern(STARTF_TITLEISLINKNAME) static Long
    UseCountChars   : extern(STARTF_USECOUNTCHARS) static Long
    UseFillAttribute: extern(STARTF_USEFILLATTRIBUTE) static Long
    UseHotKey       : extern(STARTF_USEHOTKEY) static Long
    UsePosition     : extern(STARTF_USEPOSITION) static Long
    UseShowWindow   : extern(STARTF_USESHOWWINDOW) static Long
    UseSize         : extern(STARTF_USESIZE) static Long
    UseStdHandles   : extern(STARTF_USESTDHANDLES) static Long
}

ProcessInformation: cover from PROCESS_INFORMATION {
    process: extern(hProcess) Handle
    thread:  extern(hThread)  Handle
    pid: extern(dwProcessId)  Long
}
INFINITE: extern Long

}
