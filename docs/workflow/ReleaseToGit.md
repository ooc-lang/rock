Workflow - release to git
==========================


So you've tried rock..
----------------------

So you've tried rock, the sky is shining, the sun is singing, and the
birds are blue. Wonderful.

But then you stumbled upon a bug that's already fixed in the git,
or you just heard about some new awesome feature that will be in the
next release.

But, you don't wanna wait. Then again - who could blame you for this?

Quick way
---------

  1. Extract release, cd, make
  2. git clone git://github.com/nddrylliog/rock.git && cd rock
  3. ROCK_DIST=. OOC=../rock-x.y.z*/bin/rock make self
  
And you're done! Of course, rock-x.y.z should be the number of the
release you're working from.

Don't forget to check that you're really using the latest rock you
compiled, with 'rock -V', which should display 'head', and the build
date and time. Have fun!


Makefile, thou art a heartless witch
------------------------------------

Let's walk through the different targets the Makefile offers us

  - 'make' == 'make bootstrap'. That's what you did if you installed
  from a source release. It compiles rock from a pre-generated
  set of C sources located in the build/ folder, then rebuilds it
  with itself by calling 'make self'
  
  - 'make self'. Recompile rock with itself. That overwrites the current
  rock executable with the new one (hence, will fail on OSX/Win32, which
  refuse to overwrite a running executable). For this reason, and also
  because if you recompile a messed up version, you'll have no safety net,
  I recommend to do something like 'cp bin/rock bin/safe_rock && ROCK_DIST=. OOC=bin/safe_rock make self'
  
  - 'make noclean' Used by devs who want to recompile rock with itself
  without removing the rock_tmp/ directory, hence allowing partial recompilation.
  Use with care, or don't use at all, because in some specific cases
  it introduces bugs (due to the fragile base class problem)
  
  - 'make prepare_bootstrap' Used to generate the set of C sources
  in the build/ directory. Used to make a release of rock so you
  mere mortals (hem, users) can bootstrap cleanly.
  
  - 'make grammar' Regenerate NagaQueen.c from ../nagaqueen/grammar/nagaqueen.leg
  with greg. Both nagaqueen and greg are nddrylliog's projects on github.com

