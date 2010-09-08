import structs/[HashMap, ArrayList]
import ../Process, PipeWin32
import native/win32/[types, errors]

version(windows) {

include windows

/**
   Process implementation for Win32

   :author: Amos Wenger (nddrylliog)
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

    /**
       Wait for the process to end. Bad things will happen
       if you haven't called `executeNoWait` before.
     */
    wait: func -> Int {
        CloseHandle(pi thread)
        // Wait until child process exits.
        WaitForSingleObject(pi process, INFINITE);


        exitCode : Long
        GetExitCodeProcess(pi process, exitCode&)

        CloseHandle(pi process)


        exitCode
    }

    /**
       Execute the process without waiting for it to end.
       You have to call `wait` manually.
    */
    executeNoWait: func -> Long {
        if (stdIn != null || stdOut != null || stdErr != null) {
            if(stdIn) {
                si stdInput  = stdIn as PipeWin32 readFD
                SetHandleInformation(stdOut as PipeWin32 writeFD, HANDLE_FLAG_INHERIT, 0)
            }
            if(stdOut) {
                si stdOutput = stdOut as PipeWin32 writeFD
                SetHandleInformation(stdOut as PipeWin32 readFD, HANDLE_FLAG_INHERIT, 0)
            }
            if(stdErr) {
                si stdError  = stdErr as PipeWin32 writeFD
                SetHandleInformation(stdErr as PipeWin32 readFD, HANDLE_FLAG_INHERIT, 0)
            }
            si flags |= StartFlags UseStdHandles
        }

        // Reference: http://msdn.microsoft.com/en-us/library/ms682512%28VS.85%29.aspx
        // Start the child process.
        if(!CreateProcess(
            null,        // No module name (use command line)
            cmdLine toCString(),     // Command line
            null,        // Process handle not inheritable
            null,        // Thread handle not inheritable
            true,        // Set handle inheritance to true
            0,           // No creation flags
            null,        // Use parent's environment block
            null,        // Use parent's starting directory
            si&,         // Pointer to STARTUPINFO structure
            pi&          // Pointer to PROCESS_INFORMATION structure
        )) {
            Exception new(This, "CreateProcess failed (error %d).\n" format(GetLastError())) throw()
            return -1
        }

        return pi pid
    }

}

// extern functions
ZeroMemory: extern func (Pointer, SizeT)
CreateProcess: extern func (...) -> Bool // laziness
WaitForSingleObject: extern func (...) // laziness
GetExitCodeProcess: extern func (...) -> Int // laziness
CloseHandle: extern func (Handle)
SetHandleInformation: extern func (Handle, Long, Long) -> Bool

HANDLE_FLAG_INHERIT: extern Long
HANDLE_FLAG_PROTECT_FROM_CLOSE: extern Long

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
WAIT_OBJECT_0: extern Long

}
