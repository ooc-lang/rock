rock
====

rock is an ooc compiler written in ooc - in other words, it's
where things begin to become really exciting.

'r.o.c.k' stands for 'rapid ooc compiler without kludges'.
Also, it's short and it sounds cool.

Install
-------

Note: rock will install a launching script to /usr/bin/ by default,
and its manpage to /usr/man/man1 (on *nix platforms)

You can change the prefix by running PREFIX=/usr/local/ sudo make install
for example, or even install it by hand (it's not that hard)

You have a -source release
~~~~~~~~~~~~~~~~~~~~~~~~~~

'make bootstrap && sudo make install'

You have a binary release (e.g. rock-X.X.X-linux32, rock-X.X.X-win32, etc.)
~~~~~~~~~~~~~~~~~~~~~~~~~

'sudo make install'

Troubleshooting
---------------

Help! rock doesn't find its sdk!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Here's how rock tries to find it:

1) If the ROCK_SDK environment variable is set, take that path
2) If the ROCK_DIST environment variable is set, take $ROCK_DIST/custom-sdk
3) If none of the above are set, tries to locate itself and tries ../custom-sdk
   (works if you've symlinked the rock executable to /usr/bin or something.)

Help! rock doesn't find its libraries!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The only lib rock depends on is the Boehm GC (if you don't turn it off
via -gc=off)

We have static binary builds of the Boehm GC for most platforms/archs,
look in rock/libs/

If we don't have your platform/arch, try to install the Boehm GC yourself,
and compile with -gc=dynamic (it'll link with -lgc instead of the static
binary builds)

http://www.hpl.hp.com/personal/Hans_Boehm/gc/

FAQ
---

Q: How did you bootstrap?
A: From Java: http://github.com/nddrylliog/ooc It was a lot of fun and frustration

Q: Do I need that j/ooc (java) version of the compiler to compile this?
A: No. Let it die. We distribute rock as C sources now. (Remember, ooc
   usually compiles down to C)

Q: If I don't need another ooc compiler to compile this one, how does it work?
Q: What does 'make bootstrap' do?
A: 'make bootstrap' builds a rock binary from the C sources in build/c-source,
   calls it bin/c_rock, and uses it to recompile itself to bin/rock
   
Q: I'm a naughty boy and I've read the Makefile. What does 'make prepare_bootstrap' do?
A: It uses rock to generate the build/ directory, with -driver=make. Yes, it's awesome.
   
Q: What platforms/OSes are supported?
A: It has been tested on Gentoo, Ubuntu, Windows XP (with Mingw32 and GCC 4.4),
   and OSX. 'make prepare_bootstrap' may be shaky on Windows/OSX because of 
   sed syntax differences (used to patch the produced build/Makefile). You're
   better off running it on Gentoo/Ubuntu, just like we do for source releases.

License
-------

rock is distributed under a BSD license, see LICENSE for details.
