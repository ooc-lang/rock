Workflow - release to git
==========================

Single-line Method
------------------

Giving Rock a run for its money is now quicker and easier than ever. Run the following command in your shell, and life is good. Tested and working on OS X and Ubuntu. Should work on any POSIX compliant system.

``bash -c "`curl -L http://github.com/fasterthanlime/rock/raw/master/utils/ooc-install.sh`"``


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
  2. git clone git://github.com/fasterthanlime/rock.git && cd rock
  3. ROCK_DIST=. OOC=../rock-x.y.z*/bin/rock make self
  
And you're done! Of course, rock-x.y.z should be the number of the
release you're working from.

Don't forget to check that you're really using the latest rock you
compiled, with 'rock -V', which should display 'head', and the build
date and time. Have fun!

Long way with detailed explanations
-----------------------------------

Rock is a <a href="http://en.wikipedia.org/wiki/Self-hosting">self-hosting</a> compiler, each release of rock is used to build the next release of rock. To use the git version, simply follow these steps (specific steps may vary depending on your OS):

1. Check that you have a stable release of rock (0.9.1 as of 8/05/2010), you can download the release from <a href="http://github.com/fasterthanlime/rock/downloads">here</a>.

2. Let's assume that you unpackaged the folder to /usr/share/rock-0.9.1. "cd /usr/share/" and clone the latest development copy "git clone git://github.com/fasterthanlime/rock.git"

3. "cd rock/", inside this directory execute "OOC=../rock-0.9.1/bin/rock ROCK_DIST=. make self". This will build the latest binary for rock using the stable release. This is self-hosting in action :)

4. Finally do "/path/to/rock -version" this should display "rock head, built on 2010-05-08 at 23:45". If it reports head as the version you are now using the latest release of rock. Enjoy living on the edge :)


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
  with greg. Both nagaqueen and greg are fasterthanlime's projects on github.com

