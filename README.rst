rock
====

rock is an ooc compiler written in ooc - in other words, it's
where things begin to become really exciting.

'r.o.c.k' stands for 'rapid ooc compiler without kludges'.
Also, it's short and it sounds cool.
If you can think of a better acronym, let us know.

It should compile fine under the latest j/ooc,
which you can get at http://github.com/nddrylliog/ooc

Install
-------

*rock is alpha software*, don't cry if it breaks things

  - clone nagaqueen, so that rock/ and nagaqueen/ are in the same folder (ie. they should be brothers) http://github.com/nddrylliog/nagaqueen
  - build and install greg http://github.com/nddrylliog/greg
  - build and install libyajl http://lloyd.github.com/yajl/ (make sure to `./configure --prefix=/usr` cause it defaults to /usr/local by default,
    and may not be found by gcc/ld)
  - install ooc-yajl http://github.com/fredreichbier/ooc-yajl (make sure it's in /usr/lib/ooc/, or whatever your $OOC_LIBS is defined to)

Finally,

  - create a script in /usr/bin/rock where you export OOC_DIST and call /path/to/your/rock/bin/rock
  - OR "ln -s /path/to/your/rock/bin/rock /usr/bin" and then make sure rock/ is besides ooc/ (ie. they should be brothers)

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
  - 2009-11 : Most of the resolving architecture is now there, it resolve types at module scope
              correctly. Still need to implement planned implementations that weren't in j/ooc
              (e.g. sharing Types per module, except for generics, to group resolves)
  - 2009-11 : Wohow, resolving spree. Pretty much everything resolves now, straight/member accesses/calls
              even accross different modules, with imports and all. Most of the syntax is parsed,
              except generics, and only a few AST node types are missing. The code is a lot shorter and
              clearer than j/ooc's, I have high hopes as to the maintainability of rock. Plus, it's still *fast*.
  - 2010-01 : Copying chunks of the sdk from j/ooc to rock/custom-sdk, generics for functions are mostly implemented,
              classes still to come. Most control flow structures are implemented
              (if/else/while/foreach/match/case/break/continue), decl-assign, 'This', member calls, covers, etc.

You can help! We can probably re-use like 50% of the source code from the
j/ooc codebase, so please come on #ooc-lang to know which classes need porting.

Porting is not-so-hard, just refer to the cheat sheet here: http://ooc-lang.org/cheat

License
-------

rock is distributed under a BSD license

