
# backtrace-universal

This library is loaded dynamically by ooc programs to display 'fancy
backtraces' in case of crash.

If not present, a more primitive back trace will be displayed, or, on
hostile platforms, no backtrace at all.

## Usage

The backtrace extensions allows to turn backtraces like this:

    [backtrace]
    ./otest(lang_Exception__Exception_addBacktrace_impl+0x46)[0x42e3c3]
    ./otest(lang_Exception__Exception_addBacktrace+0x20)[0x42e7f8]
    ./otest(lang_Exception__Exception_throw_impl+0x24)[0x42e746]
    ./otest(lang_Exception__Exception_throw+0x23)[0x42e889]
    ./otest(structs_ArrayList__ArrayList_get_impl+0x72)[0x436834]
    ./otest(structs_ArrayList__ArrayList_get+0x33)[0x437231]
    ./otest(structs_ArrayList____OP_IDX_ArrayList_Int__T+0x30)[0x437ca4]
    ./otest(otest__foo+0x40)[0x42950c]
    ./otest(otest__bar+0xe)[0x42952e]
    ./otest(otest__App_runToo_impl+0x16)[0x429231]
    ./otest(otest__App_runToo+0x20)[0x42928f]
    ./otest(otest____otest_closure342+0x18)[0x429587]
    ./otest(otest____otest_closure342_thunk+0x1b)[0x4295a4]
    ./otest(lang_Abstractions__loop+0x24)[0x42a745]
    ./otest(otest__App_run_impl+0x63)[0x429219]
    ./otest(otest__App_run+0x20)[0x42926d]
    ./otest(main+0x38)[0x429568]
    /lib/x86_64-linux-gnu/libc.so.6(__libc_start_main+0xf5)[0x7f5a8407f995]
    backtrace-universal/otest[0x4290e1]

Into backtraces like this:

    [fancy backtrace]
    0     print_stacktrace()           in                    (at /home/amos/Dev/tests/backtrace-universal/backtrace.c:453)                          
    1     killpg()                     in                    (at (null):0)                                                                          
    2     GI raise()                   in                    (at /build/eglibc-MUWt1e/eglibc-2.17/signal/../nptl/sysdeps/unix/sysv/linux/raise.c:56)
    3     GI abort()                   in                    (at /build/eglibc-MUWt1e/eglibc-2.17/stdlib/abort.c:92)                                
    4     Exception throw_impl()       in lang/Exception     (at /home/amos/Dev/rock/sdk/lang/Exception.ooc:221)                                    
    5     Exception throw()            in lang/Exception     (at /home/amos/Dev/rock/sdk/lang/Exception.ooc:256)                                    
    6     ArrayList get_impl()         in structs/ArrayList  (at /home/amos/Dev/rock/sdk/structs/ArrayList.ooc:84)                                  
    7     ArrayList get()              in structs/ArrayList  (at /home/amos/Dev/rock/sdk/structs/ArrayList.ooc:43)                                  
    8     __OP_IDX_ArrayList_Int__T()  in structs/ArrayList  (at /home/amos/Dev/rock/sdk/structs/ArrayList.ooc:292)                                 
    9     foo()                        in otest              (at /home/amos/Dev/tests/backtrace-universal/otest.ooc:20)                             
    10    bar()                        in otest              (at /home/amos/Dev/tests/backtrace-universal/otest.ooc:25)                             
    11    App runToo_impl()            in otest              (at /home/amos/Dev/tests/backtrace-universal/otest.ooc:53)                             
    12    App runToo()                 in otest              (at /home/amos/Dev/tests/backtrace-universal/otest.ooc:65)                             
    13    __otest_closure342()         in otest              (at /home/amos/Dev/tests/backtrace-universal/otest.ooc:48)                             
    14    __otest_closure342_thunk()   in otest              (at /home/amos/Dev/tests/backtrace-universal/otest.ooc:47)                             
    15    loop()                       in lang/Abstractions  (at /home/amos/Dev/rock/sdk/lang/Abstractions.ooc:2)                                   
    16    App run_impl()               in otest              (at /home/amos/Dev/tests/backtrace-universal/otest.ooc:47)                             
    17    App run()                    in otest              (at /home/amos/Dev/tests/backtrace-universal/otest.ooc:61)                             
    18    main()                       in                    (at /home/amos/Dev/tests/backtrace-universal/otest.ooc:1)                              
    19    libc_start_main()            in                    (at /build/eglibc-MUWt1e/eglibc-2.17/csu/libc-start.c:294)                             
    20    _start()                     in                    (at (null):0)                                               

Basically: it finds line numbers, demangle ooc symbols, and formats it nicely.


## Requirements

Basically, we need libbfd and gettext. bfd is usually in binutils,
gettext provides -lintl.

### Windows

On Windows, when building with MinGW, no additional dependency needs
to be installed.

Other toolchains than MinGW aren't supported at this time.

### OSX

On OSX, [Homebrew][brew] is recommended to install dependencies.

[brew]: http://brew.sh

To install all dependencies, do:

    brew install binutils gettext

In case those don't work, the `Makefile` will warn you.

### Linux

On Debian, `binutils-dev` is required. On other distributions, package
names may vary. Make sure `-lintl` is available as well.

