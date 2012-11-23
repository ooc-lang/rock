[![Build Status](https://secure.travis-ci.org/nddrylliog/rock.png?branch=master)](http://travis-ci.org/nddrylliog/rock)

# rock

  * [ooc](http://ooc-lang.org/)
  * [rock](https://github.com/nddrylliog/rock)

rock is an ooc compiler written in ooc - in other words, it's
where things begin to become really exciting.

it has been bootstrapping since April 22, 2010 under Gentoo, Ubuntu,
Arch Linux, Win32, OSX...

## Prerequisites

You need the following packages when building rock:

* GNU Make (`make` or `gmake`, depending on your operating system)
* boehm-gc
* tar (for extracting the C sources)
* bzip2 (used by tar)

## Get started

Run `make rescue` and you're good.

## Wait, what?

`make rescue` downloads a set of C sources, compiles them, uses them to compile your copy of rock,
and then uses that copy to recompile itself

Then you'll have a 'rock' executable in bin/rock. Add it to your PATH, symlink it, copy it, just
make sure it can find the SDK!

## Install

See the INSTALL file

To switch to the most recent git, read [ReleaseToGit](https://github.com/nddrylliog/rock/blob/master/docs/workflow/ReleaseToGit.md)

## License

rock is distributed under a BSD license, see LICENSE for details.
