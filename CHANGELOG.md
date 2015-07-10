
## 0.9.10 release (2015-07-11)

This release represents 196 commits, 178 files changed with 8520 additions and
4468 deletions, 64 issues closed, and about 30 pull requests merged!

It contains a lot of contributions from @zhaihj, who has been maintaining their
own fork of rock and fixing issues while I was gone. It also contains the bulk
of the work of @shamanas right after 0.9.9 was released, and many reports
from the Cogneco team, @davidhesselbom in particular. Welcome also to @ds84182,
@ibara, and @kirbyfan64 for their first patch!

The 0.9.10 release is codenamed "rita" because it's the name of my dog! (-- amos)
Adopted her a week ago, and doesn't really care for ooc generics bugs,
but she's lovely nonetheless

Summary:

  - Attempted to better comment & reformat some parts of rock.
  - Test suite is now 164 tests strong, and uses sam's new 'sam-assert'
    library that has `describe` and `expect` instead of a lot of duplicated
    code and ugly exit(1) calls.
  - Generics bugfixes by the dozen - more things work now, but also more
    things are checked and trigger compile errors instead of runtime crashes
    or invalid C code generation.
  - Same goes for operator overloads
  - Same goes for closures

Features:

  - New CMake driver, generates `CMakeLists.txt`, good enough to compile rock! (#847)
  - New `--use` option to force the main module to 'use' an ooc library. Used
    by sam to add its 'sam-assert' (#902)
  - The `Imports` directive in usefiles now supports grouped import syntax (#904)
  - When a call to a function is slighty wrong, rock is now a lot more helpful
    in a lot of cases (#894)
  - Exceptions now print the word `exception` in red when thrown. Apparently
    a big plus! (#862)
  - New operator, `??`, the null coalescing operator (#809)

Generics bugfixes:

  - Assignment between parameterized types is now checked. (And oddly enough, the
    sdk, rock, and all tests still compile..) (#842)
  - Accessing a generic member used to require a cast, but not any more (#889, #425)
  - Properties of generic types used to cause a mysterious `gc_malloc` unresolved
    error, well, not anymore. (#840)
  - When matching against a parameterized type (e.g. ArrayList<T>), rock used
    to complain about the lack of typeArgs. It's now valid to have an
    unqualified parameterized type in a match (#802)
  - rock doesn't segfault on parameterized function call (which is invalid ooc) (#811, #833)
  - The type arg of a parameterized function is now inferred from all arguments
    of that type, not only the first. Also, an error is thrown if they're incompatible (#825, #826)
  - Don't generate unnecessary temporary variable/memcpy calls because of cast (#892)
  - Casting to a generic type is now forbidden (except from Pointer) (#891)
  - A subtle cover-template bug I really don't want to talk about (#887)
  - String interpolation inside cover templates was broken (#886)

Bugfixes:

  - Common root algorithm now follows C99 rules as closely as possible when
    dealing with numeric types.
  - Various problems related to capturing variables in nested closures are
    now fixed (#864)
  - murmurHash was broken because of SizeT changes, is now fixed. (#874)
  - Additional `/` after `///` or additional `*` after `/**` are now interpreted as
    regular comments, not oocdocs. To the ASCII art machines! (#829)
  - All assignment operators are now overloadable (yes, even `%=`, which doesn't
    make any sense in C-land.. but this is not C-Land). (#869)
  - Casting between ooc array types is now illegal, this prevents many runtime crashes (#795)
  - Array literal type is now inferred from all elements (tries to find common root)
    rather than the first element (#881)
  - Fixed size-related bug in Array.h (missing parenthesis in C macros, grr.) (#878)
  - It is now possible to declare abstract operators in classes. (#796)
  - Top-level function definitions no longer accept 'abstract', 'static', and
    'final' modifiers since they don't make sense (#797)
  - Cover types and 'Object' are now incompatible at compile-time, that will
    prevent runtime crashes (#803, #827)
  - Function implementation correctness is better checked (when implementing an
    interface) (#805)
  - Emit a warning when assigning to a field in by-value cover constructor (tl;dr
    use init: func@ if you insist on having cover constructors..) (#832)
  - Overloading a final function is illegal and should be a compile-time error (#851)
  - Overloading a constructor but swapping its arguments - if one of them was a
    FuncType - could cause a crash (crazy right?) (#856)
  - Declaring multiple variables via a tuple-declaration could conflict with
    function parameters. It's now checked. (#863)
  - Declaring multiple variables via a tuple-declaration was sometimes shadowed
    by class members. (#903)
  - Using match on `args` from the main function was somehow broken (#866)
  - Reduce amount of warnings (only use -rdynamic on gcc, Array.h tweaks) (#867)
  - Turned 'Casting pointer to a struct' into a proper compile error rather
    than just throwing an exception (#893)
  - Using a composite-assign operator (+=, -=) on an expression that returned
    a generic type generated crashing C code. (#890)
  - Operator overloads used to be checked on use, not on definition.. (#888)
  - Was assuming most anonymous functions used ACS, but they don't. (#885)
  - When assigning between closures, sometimes did a double-wrap, which generated
    invalid C code (#884)
  - Nested closures that capture something by reference were broken - the innermost
    closure was getting the address of the address. (#882)
  - Globally-declared Func objects are now callable (#876)
  - Passing an extern const to a generic function (or trying to get its address)
    resulted in a segfault at runtime (#897)
  - Calling a function returned from another call was broken sometimes (#901)
  - If-else generation was broken in version blocks sometimes (#534, #900)
  - EscapeSequence was not properly padding hex escapes with zeroes (#877)
  - Usefile searching was slightly wrong (#849)
  - When there's a circular dependency, show the dependency graph (#850)

Docs:

  - Default-valued parameters are now documented (#808)
  - Fixed doc of properties with simple getter/setter (#812)
  - Comments in math/Random were wrong for 'random' (#870)
  - Added mention of Sublime Text in 'editors' section of website (#871)
  - Fixed documentation of extern enum syntax (#899)

## 0.9.9 release (2014-08-17)

  - rock has been relicensed to MIT (#755)
  - Boehm GC is now properly vendored - it lives in the `vendor` directory and is installed
  to `vendor-prefix` - the new targets `boehmgc` and `boehmgc-clean` have been added to the
  Makefile (#768)
  - Changes to git workflow: the `master` branch is now bleeding-edge, `stable`
    is stable, and version branches still exist (#794)
  - rock now supports library precompilation - when compiling from a .use file that has
  no Main field (#733)
  - io/File now has `find`, `rm`, and `rm_rf` to find files, remove files, and remove files
  and directories recursively (#734, #735, #737, #738)
  - ArrayAccess type checking has been relaxed to better accomodate operator overloading
  with non-numeric indices (#740)
  - SequenceDriver fixes related to archives - better incremental (re)compilation support (#741)
  - Don't fopen files to check if they exist anymore (performance increase + correctness) (#742)
  - Numeric literal suffixes: `d` and `f` - no-suffix floating point literals now default
  to Double, which is coherent with C/C++ (#749)
  - String format now supports the `%ull` specifier (#750)
  - C arrays declarations like `a: Int* = [1, 2, 3]` now work as expected. (#751)
  - Passing a pointer to a generic function will now pass the `Pointer` type, not the
  inner type (Int, etc.) (#752)
  - .use files now support the `BinaryPath` directive for executable name (#754)
  - .use files now support the `OocLibPaths` directive to add to the ooc libs search path (#756)
  - Warnings about unknown version names now happen only once per unknown name (as opposed
  to: a fuckload) (#757)
  - Fix for each usage on `Range` instances (#759)
  - Make `match` autocast work with primitive (#760)
  - Namespaced import fixes (#766)
  - Complex tuple assignment no longer clobbers left-hand-side variables (#774)
  - Fixed too-strict operator overloading checks for unary operators (#780)
  - Fixed code generation error with properties in covers (#781, #782)
  - Always exit with non-zero code even in quiet mode (#786)
  - Always print C compiler failures to stderr, even in quiet mode (#787)
  - Add support for main: func (args: String[]) (#788)
  - Add support for scientific notation in floating point literals (#784)
  - Code quality fixes to the `fancy_backtrace` extension (#779)
  - text/Shlex now has inline documentation and a test case (#785)
  - Various Win32 Pipe & Process fixes (e.g. #791), notably, ProcessWin32 now passes
    environment variables (#792) and redirects std{in,err,out} correctly (#793)
  - Various luaffi backend fixes (#769, #770, #771, #772, #773)
  - Various performance improvements in rock's compilation process (#744, #743)
  - Various test cases added and ported to Win32 (#790)

## 0.9.8 release (2013-11-27)

  - Added a few rock tests, they are now runnable by sam, and ran on each git push
    on Travis, see `test/README.md`.
  - Added interpolated string literals, using a Ruby-like syntax, `"Like #{this}"`
  - Added raw string (CString) literals, e.g. `c"C string here"`
  - `extend` blocks can now define properties that do not require a field definition (virtual properties)
  - Added another form of foreach, `for ((index, element) in iterable)`, where index is an Int from 0
    to `iterable size()`.
  - Added the `::=` operator for 'property declarations from expr', for example
    `fullName ::= "#{firstName} #{lastName}"`
  - Added a base64 encoder and decoder to the sdk.
  - Added --target and --host option for cross compiling, successfully tested cross-compiling from
    Linux to Windows and OSX.
  - Downgraded to Boehm GC 7.2e, which supports Windows threads properly, making this
    the first release in years where the GC won't go batshit crazy if you use threads on Win32.
  - Fix cross-library base class problem (#541) - partial recompilation should now
    work all the time.
  - The `fancy_backtrace` extension now scans the PATH to find the executable
    if dladdr doesn't return an absolute path.
  - The `Pkgs` directive of .use files can now be in version blocks.
  - Tuple assignment now works as expected. The return expression of a multi-return method
    can now be another multi-return method call.
  - Unary minus operator precedence fixed, behaves as intended with expressions now.
  - Unary plus operator added, behaves like unary minus, can be overloaded.
  - Unary operator overloads can now be instance methods instead of just functions.
  - Better error reporting, both with missing imports and braced statements.
  - Relative imports and imports from .use files are now restricted to their respective
    SourcePath elements.
  - Rock now has stricker type checking algorithms for returns from void and non-void functions.
  - Code generation is now faster and much less IO-intensive due to us re-using line info
    from nagaqueen instead of recomputing it each time we output a `#line` C directive.
  - Added banned flags and banned pthread on Win32.
  - Separated trails where it makes sense, this way we don't get really weird error messages.
  - Floating point numbers with no digits are no longer allowed by the grammar.
  - Rock is less verbose by default with `-v`, use `-vv` to return to previous `-v` behavior,
    and `-vvv` to be drowned in Tinkerer messages.
  - Fixed a few AST generation bugs.

## 0.9.7a release (2013-10-14)

  - Fix Win32 build, some extern variables were in fact not.

## 0.9.7 release (2013-10-09)

  - Author names have been removed from all source files, to encourage contributions
    rather than false ownership. The AUTHORS.md file still contains all contributor names.
  - Improved backtrace and error condition reporting, with unmangling and pretty printing
    on OSX, Linux, and Windows. Can be found in extensions/, made with `make extensions`,
    loaded as a dynamic library if found.
  - Debug and production profile choosable with -pg and -pr, debug is now the default
  - New module: os/Dynlib for dynamic library loading
  - New methods: Thread yield(), Thread currentThread(), Thread isAlive?(), Thread wait~timed()
  - Fixed UDPSocket and all other socket stuff, cross-platform again.
  - Fixed line numbers on Windows.
  - Add closest match when we can't resolve a call (better error reporting)
  - Fix weird case of additional imports that shouldn't have been needed (resolving fix)
  - Translate `__bang` and `__quest` back into `?` and `!` in rock error messages
  - Improve error reporting inside blocks and all braced constructs (e.g. scopes)
  - Color error output by default
  - Add CString println()
  - Add non-blocking I/O for pipes
  - New PipeReader and PipeWriter implementations, extending io/Reader and io/Writer
  - Fix BufferWriter
  - Add a bunch of tests in test/
  - Fix Windows 64-bit support, both in sequence and make drivers
  - Link the GC dynamically on Windows, still not resolved that threading issue.
  - Make ArrayList and ArrayListIterator safer (check out of bounds operations more
    thoroughly)
  - File getAbsolutePath() now returns the case-sensitive path on Windows
  - Empty cases in merge no longer make rock crash
  - Allow octal sequences that don't start with 0 in EscapeSequence
  - Force standard main prototype
  - Fix `>>=` and `<<=` operators
  - New method: File rebase()
  - mkdirs() now applies mode to all subdirectories created
  - Fix generic type name issue (#693)
  - Add abs function in math
  - Avoid huge memory leak with repeated clear in structs/HashMap
  - match now evaluates its condition only once, no matter the number of cases,
    avoiding undesired side effects.
  - Avoid entering an infinite loop when trying to be helpful about compiler errors.

## 0.9.6 release (2013-02-20)

  - Cover templates are in! Planning for cleaner arrays in 0.9.7 - in the meantime,
    fun example here: https://gist.github.com/nddrylliog/4967552 (@nddrylliog)
  - Version blocks in .use files - not entirely friendly to the make driver yet,
    but SequenceDriver and AndroidDriver handle those beautifully. (@nddrylliog)
    Full documentation about use files here: http://docs.ooc-lang.org/
  - operator@ variant (same as func@ but for operator overloads) - @nddrylliog
  - Operator overloads declaration within types, which fix some import issues.
    See #583 for details: https://github.com/nddrylliog/rock/issues/583 (@nddrylliog)
  - Stricter warnings for field redefinition in classes (@shamanas)
  - Nested closures are more reliable (@shamanas)
  - Instead of going through an intermediate archive, rock now computes the
    dependency graph of your project to pass linker arguments in the right order (@nddrylliog)
  - SequenceDriver was omitting -g, which made debugging significantly harder (@nddrylliog)
  - Invalid uses of break and continue inside of loops are now rock errors (@shamanas)
  - For the rest, this is mostly a bugfix and internal clean-ups release -
    bugs related to generics, closures, type inference in match (@shamanas & @nddrylliog)
  - The --sourcepath has been deprecated, everything goes through .use files now (@nddrylliog)
  - The make driver produces a 'clean' target to remove all binary objects now. (@nddrylliog)

## 0.9.5 release (2013-02-12)

  - Fixed a long-standing issue with varargs usage in ternary expressions
    (#311) by @shamanas
  - Processes launched in Unix systems now check for segfault (@shamanas)
  - nagaqueen (and thus rock) are now able to parse .ooc files from memory, not
    only from files. This allows nice things such as
    https://github.com/nddrylliog/scissors (@nddrylliog)
  - Add '#pragma once' in generated headers, this makes compilation faster for
    some (gcc/clang), and header guards are still here as a fallback for old
    compilers (@shamanas)
  - 'CustomPkg' support in .use files, see
    https://github.com/nddrylliog/rock/issues/492 - used in scissors for
    llvm-config, but also in ooc-sdl2 for sdl2-config, for example
    (@nddrylliog)
  - 'Linker' support in .use files, great when using ooc-llvm because it
    requires the final linking step to be done with g++ (@nddrylliog)
  - Fixed a strange varargs but that was basically an off-by-one error  
  - Make relative 'IncludePaths'/'LibsPaths' work in .use files (@nddrylliog)
  - Display command line in case rock fails to execute a process on Win32
  - 'Frameworks' support for .use files, useful when building on OSX
    (@nddrylliog)
  - String + Number now does concatenation again (@shamanas)
  - Fix GetTimeFormat usage on Win32, had a null byte before (@nddrylliog)
  - Sequence driver now uses multiple threads - 1.5x your number of processors
    by default. You can control the number of parallel jobs with '-j'
    (@nddrylliog)
  - Cleanup os/Terminal implementation, make it cross-platform again in a
    cleaner way (@nddrylliog)
  - Enum decls were buggy, sometimes they couldn't be used because of undefind
    symbols, as caused by invalid generated C code - that's now fixed.
    (@nddrylliog)
  - Lots of cachelib fixes, recompilation now almost always works (#541 is
    still an issue), SequenceDriver is a lot cleaner, CombineDriver is gone,
    and cachelib is now the one true way - and never hangs anymore on Win32.
    (@nddrylliog)
  - rock releases have codenames again! This one is panda.
  - Add built-ins - symbols in ooc code that will get replaced while resolving.
    At the time of this release, those are: __BUILD_DATETIME__,
    __BUILD_TARGET__, __BUILD_ROCK_VERSION__, __BUILD_ROCK_CODENAME__,
    __BUILD_HOSTNAME__
  - Fix match-related bugs with catch-all clauses being the only ones / first
    ones (@shamanas)
  - Varargs were broken on ARM - that's now all fixed, and ooc code runs
    beautifully on both the Raspberry PI (rock bootstraps) and ARM Android
    phones (game projects) (@nddrylliog, @duckinator, @geckojsc)
  - The sdk is now a proper library with a .use file and default imports -
    instead of having ugly hardcoded hacks in the compiler instead. That makes
    swapping the default sdk with your own real easy (@nddrylliog)
  - $OOC_LIBS now accepts multiple paths, separated by the File separator (: on
    *nix, ; on Windows) - that's useful when swapping SDKs, or when having to
    use different usefiles depending on the platform, to work around #561
    (@nddrylliog)
  - Make process launching more solid on all platforms, introducing
    os/ShellUtils that's been imported from rock's codebase. (@nddrylliog)
  - Process launching on Win32 now supports cwd (current working directory)
    (@nddrylliog)
  - The explain backend has been removed for a slimmer codebase. It may find a
    second life as a separate tool (@nddrylliog)
  - dot output (to graph dependencies between modules) has been removed, for a
    slimmer codebase. I'm afraid it's dead for good, but it was fun while it
    lasted! (@nddrylliog)
  - Fix an annoying bug with properties: when we had a property access on the
    right hand side of an assignment, it assumed it was a real member. Now
    handled correctly (@nddrylliog)
  - 'Additionals' support in .use files - to use .c code bases directly in your
    .ooc bindings, example: nagaqueen-generated grammar in rock.use, and
    stb_image.c in https://github.com/nddrylliog/ooc-stbi
  - Add 'seek' to the Reader interface - it's actually handy to subclass this
    for alternative I/O, see this example with SDL_rwops:
        https://github.com/nddrylliog/dye/blob/gles/source/dye/gritty/io.ooc
        (@nddrylliog)
  - Android driver added, generate files in your jni/ directory (specify with
    -outpath), and generate Android.mk files to be used with ndk-build.
    (@nddrylliog)

## 0.9.4 release (2012-11-21)

  - BSD support added by @duckinator
  - Fixed compilation on ArchLinux x64
  - Fixed and ported parts of the SDK for win32 support, thanks to @nddrylliog
  - Added '=>' operator (not overloaded by the SDK) by @shamanas
  - Added File getReducedPath
  - Added namespace type support
  - Added single-line version blocks
  - Cleaned up rock's codebase thanks to @duckinator
  - Various Makefle fixes and additions
  - Default main() generated by rock now returns 0 as expected
  - Added support for Travis-CI builds
  - Various scoring improvements (for function types, operators, ...)
  - clone, merge and merge! added to HashMap by @nddrylliog
  - Nested array support added by @shamanas
  - Better errors for dot-args and ass-args outside of non-static methods
  - Lots of bugfixes by @shamanas, @nddrylliog, @duckinator, @showstopper, @fredreichbier

## 0.9.3 release (2011-12-13)

  - OSX support is back! Thanks @nilium for upgrading us to the latest
    libatomic_ops (yup, it was that simple).
  - rock -r now doesn't display warnings anymore, cause it's irrelevant
    if you just want to run the program
  - rock -x now cleans completely the directory (.libs / rock_tmp)
  - rock without any options will look for a .use file and if there's
    a "Main:" compile an executable, otherwise static and dynamic libraries
  - The -help message is now a lot more detailed, it explains a lot of
    debug/obscure options we've been keeping for ourselves up till now.
  - Added eachUntil() and contains?() to List
  - Add XPath-like selectors to HashBag
  - Added a convenient text/json module
  - FileWriter asPipe, createTempFile
  - Added an exponent operator (**) to the grammar, it's not overriden
    by default for integer types, so don't use it yet :) When everybody
    has migrated to 0.9.3, we'll include that in 0.9.4
  - Again, lots of bugfixes and cleanups, lookup the commits

## 0.9.2 release (2011-09-05)

  - Lots of bugfixes, refactorings (see GitHub milestone), thanks to
    @shamanas, @duckinator, @fredreichbier, @showstopper, @tsion, @rofl0r, @nddrylliog
  - New Socket API by @duckinator (aka Nicholas Markwell)
  - FreeBSD support by @nikobordx
  - Better error messages through nagaqueen fixes
  - Enums now start at 0 instead of 1 (a really hard change to make
    in a self-hosting compiler)
  - String literal optimizations - allocate once, not per-usage
  - New command-line options: libfolder, staticlib, dynamiclib
  - yajit removal, it wasn't being used anywhere in rock
  - New Time methods
  - Somehow the SDK now includes an HTTPRequest and RestClient?
    Courtesy of @pheuter aka Mark Fayngersh
  - Added loop(|| ...)
  - Variants of each(...) with index
  - main now acceps String* as parameter (@showstopper aka Yannic Ahrens)
  - version blocks now support else {} (@nddrylliog aka Amos Wenger)
  - Probably the biggest change, which also explains why this release took
    a whopping 15 months - newstr, ie. String is now a class, and CStrnig
    is now the cover of char*. It's handled smoothly in many cases, thanks
    to implicit cases and related trickery but it's a scar rock will always bear.

## 0.9.1 release (2010-06-02)

  - 2010-05 reverse iterators / backIterator() added to collection classes
    by Noel Cower (nilium)
  - 2010-05 lib-caching was added to rock, and partial recompilation is
    much smarter with the .libs/ directory and .cacheinfo files.
    Can be disabled with -nolibcache. Added by Amos Wenger (nddrylliog)
  - 2010-05 ACS (awesome closure syntax) is in! Our closures capture syntax
    and even generate trampoline functions to translate generic types
    into specific types. Thanks Yannic Ahrens (showstopper) !
  - 2010-05 oos now compiles under rock - we still have to figure out
    a good syntax for stack-allocation of C arrays.
  - 2010-04 Added support for ooc arrays, early implementation of this
    proposal: https://lists.launchpad.net/ooc-dev/msg00146.html

## 0.9.0 release (2010-04-23 - 600+ downloads)

  - 2010-04 : rock bootstraps under Gentoo, Ubuntu, Win32, OSX,
    the first release of the 0.9.x branch is out!

## pre-history

  - 2010-02 : rock compiles most, if not all, generic collection classes, produces correct code.
    we're going toward self-hosting, fixing bugs as we encounter them.
  - 2010-02 : twitter announcement: for the first time, rock, a 10k SLOC pure ooc codebase,
    compiles under Win32, and produces executables with gcc. party?
  - 2010-01 : Copying chunks of the sdk from j/ooc to rock/custom-sdk, generics for functions are mostly implemented,
    classes still to come. Most control flow structures are implemented
    (if/else/while/foreach/match/case/break/continue), decl-assign, 'This', member calls, covers, etc.
  - 2009-11 : Wohow, resolving spree. Pretty much everything resolves now, straight/member accesses/calls
    even accross different modules, with imports and all. Most of the syntax is parsed,
    except generics, and only a few AST node types are missing. The code is a lot shorter and
    clearer than j/ooc's, I have high hopes as to the maintainability of rock. Plus, it's still *fast*.
  - 2009-11 : Most of the resolving architecture is now there, it resolve types at module scope
    correctly. Still need to implement planned implementations that weren't in j/ooc
    (e.g. sharing Types per module, except for generics, to group resolves)
  - 2009-11 : Overwhelmed by complexity, rewrote the grammar as a reusable piece, in a separate
    github project. nagaqueen (its fancy name) is now needed to make rock compile
  - 2009-10 : Made a leg frontend, builds the AST, ported a lot of Java code with itrekkie,
    rock now compiles things =)
  - 2009-10 : Creating the AST structure, code generation works well, putting the
    frontend on hold for a moment
  - 2009-09 : The tokenizing code is all there, and it's working simply great.
    Now onto constructing AST nodes.
  - 2009-06 : Basic structure, it's gonna be some time till it can do anything useful








