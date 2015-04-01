import os/Time
import structs/[ArrayList,List]

/**
   seed rand: C stdlib function to initialize the random number generator from a given seed.
 */
srand: extern func(Int)

/**
   C stdlib function to generate a random integer between 0 and INT_MAX
 */
rand: extern func -> Int
RAND_MAX: extern const Int

// Executed at loadtime: we initialize the random number generator from
// the current time in microsecond
srand(Time microtime())

/**
   Collections of functions used to generate pseudo-random numbers.
 */
Random: class {

    /** State variable used for our internal fast pseudo-random number generator */
    state := static Time microtime()

    /**
       :return: a pseudo-random number between 0 and INT_MAX, generated using
       the C functions srand/rand
     */
    random: static func -> Int {
        return rand()
    }

    /**
       :param start: Lower bound, inclusive
       :param end: Upper bound, inclusive
       :return: A pseudo-random number between `start` (inclusive) and `end` (inclusive),
       generated using the C functions srand/rand
     */
    randInt: static func(start, end: Int) -> Int {
        return randRange(start, end + 1)
    }

    /**
       :param start: Lower bound, inclusive
       :param end: Upper bound, inclusive
       :param ex: List of integers to exclude (ie. to never return)
       :return: A pseudo-random number between `start` (inclusive) and `end` (inclusive),
       generated using the C functions srand/rand, that is not comprised in `ex`
     */
    randInt: static func ~exclude(start, end: Int, ex: List<Int>) -> Int {
        return exclude(start, end, ex, randInt)
    }

    /**
       :param start: Lower bound, inclusive
       :param end: Upper bound, exclusive
       :return: A pseudo-random number between `start` (inclusive) and `end` (exclusive),
       generated using the C functions srand/rand.
     */
    randRange: static func(start, end: Int) -> Int {
        width := end - start
        return start + (random() % width)
    }

    /**
       :param start: Lower bound, inclusive
       :param end: Upper bound, exclusive
       :param ex: List of integers to exclude (ie. to never return)
       :return: A pseudo-random number between `start` (inclusive) and `end` (exclusive),
       generated using the C functions srand/rand, that is not comprised in `ex`
     */
    randRange: static func ~exclude(start, end: Int, ex: List<Int>) -> Int {
        return exclude(start, end, ex, randRange)
    }

    /**
       :param l: A list to choose an element from randomly.
       :return: An element pseudo-randomly picked from the given list
     */
    choice: static func <T> (l: List<T>) -> T {
        return l get(randRange(0, l size))
    }

    /**
       :param start: First parameter of `f` (usually the lower bound)
       :param end: Second paramter of `f` (usually the upper bound)
       :param ex: Exclusion list - exclude will never return a number that
       is included in ex.
       :param f: Random number generation function, usually randInt, randRange,
       fastRandInt, or fastRandRange
       :return: The first result of f(start, end) that is not contained in ex.
     */
    exclude: static func(start, end: Int, ex: List<Int>, f: Func (Int, Int) -> Int) -> Int {
        toRet := f(start, end)
        while (ex contains?(toRet)) {
            toRet = f(start, end)
        }
        return toRet
    }

    /**
       :return: A pseudo-random number between INT_MIN and INT_MAX.
       This method is generally faster than random() but the distribution
       of the random numbers may be less even / repeat more easily.

       See http://software.intel.com/en-us/articles/fast-random-number-generator-on-the-intel-pentiumr-4-processor/
       for more infos
     */
    fastRandom: static func -> Int {
        state = 214013 * state + 2531011
        return (state>>16) & 0x7fff
    }

    /**
       :param start: Lower bound, inclusive
       :param end: Upper bound, inclusive
       :return: A pseudo-random number between `start` (inclusive) and `end` (inclusive),
       generated using the fast random number generator fastRandom()
     */
    fastRandInt: static func(start, end: Int) -> Int {
        return fastRandRange(start, end+1)
    }

    /**
       :param start: Lower bound, inclusive
       :param end: Upper bound, inclusive
       :param ex: List of integers to exclude (ie. to never return)
       :return: A pseudo-random number between `start` (inclusive) and `end` (inclusive),
       generated using the fast random number generator fastRandom(), that is not comprised in `ex`
     */
    fastRandInt: static func ~exclude(start, end: Int, ex: List<Int>) -> Int {
        return exclude(start, end, ex, fastRandInt)
    }

    /**
       :param start: Lower bound, inclusive
       :param end: Upper bound, exclusive
       :return: A pseudo-random number between `start` (inclusive) and `end` (exclusive),
       generated using the fast random number generator fastRandom()
     */
    fastRandRange: static func(start, end: Int) -> Int {
        width := end - start
        return start + (fastRandom() % width)
    }

    /**
       :param start: Lower bound, inclusive
       :param end: Upper bound, exclusive
       :param ex: List of integers to exclude (ie. to never return)
       :return: A pseudo-random number between `start` (inclusive) and `end` (exclusive),
       generated using the fast random number generator fastRandom(), that is not comprised in `ex`
     */
    fastRandRange: static func ~exclude(start, end: Int, ex: List<Int>) -> Int {
        return exclude(start, end, ex, fastRandRange)
    }

    /**
       :param l: A list to choose an element from randomly.
       :return: An element pseudo-randomly picked from the given list
     */
    fastChoice: static func <T> (l: List<T>) -> T {
        return l get(fastRandRange(0, l size))
    }

} 





