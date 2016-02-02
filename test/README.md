
[sam]: https://github.com/ooc-lang/sam
[travis]: https://travis-ci.org/ooc-lang/rock/builds 

## about rock tests

Tests in this directory are ran with [sam][sam]

Here are the general rules:

  * The simplest form of test is expected to compile, and exit with 0
  * Tests are split between 'compiler' tests (language features) and 'sdk' tests
  * To expect compiler errors, one may use the `//! shouldfail` sam directive
  * To expect that a program crashes, one may use the `//! shouldcrash` sam directive

sam directives are just carefully crafted comments in the
ooc source code. For example, this tests that an invalid ooc file
will not compile:

```ooc
// !shouldfail

main: func {

// missing closing brace here on purpose
```

`shouldcrash` is used similarly, but its use should normally be very rarely required.

## running tests

Tests are ran on each push, in every branch, by the [Travis][travis]
continuous integration system.

If you want to run tests locally, you may want to [clone sam][sam], install it, and
then run:

```
sam test
```

From the rock directory.

To run a single group of tests, for example, `test/compiler/generics`, run:

```
sam test rock.use test/compiler/generics
```

## cross-platform

Tests should be, as much as possible, written so they compile and run on
Windows, Mac OSX, and Linux.

Linux is a must, since the continuous integration builds are done there,
Mac OSX is usually a no-brainer, and Windows is a bonus, but appreciated.

## coverage

We have no test coverage tool so far. The general consensus on the quantity
of tests is 'not enough'.

