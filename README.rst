rock
====

rock is an ooc compiler written in ooc - in other words, it's
where things begin to become really exciting.

'r.o.c.k' stands for 'rapid ooc compiler without kludges'.
Also, it's short and it sounds cool.
If you can think of a better acronym, let us know.

It should compile fine under the latest j/ooc,
which you can get at http://github.com/nddrylliog/ooc

When rock will be stable enough, we're going to ditch j/ooc for good
and happily live as chicken and egg forever.

Install
-------

*rock is alpha software*, don't cry if it breaks things

You'll need the latest nagaqueen grammar along the rock/ folder: http://github.com/nddrylliog/nagaqueen
Since 2009-11-05, nagaqueen relies on greg instead of peg-leg again.: http://github.com/nddrylliog/greg

Two ways, either
  - create a script in /usr/bin/rock where you export OOC_DIST and call /path/to/your/rock/bin/rock
  - "ln -s /path/to/your/rock/bin/rock /usr/bin" and then make sure rock/ is besides ooc/ (ie. in the same parent folder)

Progress report
---------------

  - 2009-06 : Basic structure, it's gonna be some time till it can do anything useful
  - 2009-09 : The tokenizing code is all there, and it's working simply great.
              Now onto constructing AST nodes.
  - 2009-10 : Creating the AST structure, code generation works well, putting the 
              frontend on hold for a moment
  - 2009-10 : Made a leg frontend, builds the AST, ported a lot of Java code with itrekkie,
  	      rock now compiles things =)
  - 2009-11 : Overwhelmed by complexity, rewrote the grammar as a reusable piece, in a separate
              github project. nagaqueen (its fancy name) is now needed to make rock compile

You can help! We can probably re-use like 50% of the source code from the
j/ooc codebase, so please come on #ooc-lang to know which classes need porting.

Porting is not-so-hard, just refer to the cheat sheet here: http://ooc-lang.org/cheat

P.S: Did I mention bootstrapping is awesome?
P.P.S: If this project description isn't formal enough for you, then rock
is probably not ready for you yet. Or the other way around. Or not. Who knows.
P.P.P.S: rock is distributed under the BSD license, as usual.
