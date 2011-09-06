A few questions
---------------

Q: How did you bootstrap?
    A: From Java: http://github.com/nddrylliog/ooc It was a lot of fun and frustration
Q: Do I need that j/ooc (java) version of the compiler to compile this?
    A: No. Let it die. We distribute rock as C sources now. (Remember, ooc
    usually compiles down to C)
Q: If I don't need another ooc compiler to compile this one, how does it work? What does 'make bootstrap' do?
    A: 'make bootstrap' builds a rock binary from the C sources in build/c-source,
    calls it bin/c_rock, and uses it to recompile itself to bin/rock
Q: I'm a naughty boy and I've read the Makefile. What does 'make prepare_bootstrap' do?
    A: It uses rock to generate the build/ directory, with -driver=make. Yes, it's awesome.
Q: What platforms/OSes are supported?
    A: It has been tested on Gentoo, Ubuntu, Windows XP (with Mingw32 and GCC 4.4), and OSX.
    'make prepare_bootstrap' may be shaky on Windows/OSX because of 
    sed syntax differences (used to patch the produced build/Makefile). You're
    better off preparing bootstrap on a Linux, just like we do for source releases.


