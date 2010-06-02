import os/Time
import structs/[ArrayList,List]

srand: extern func(Int)
rand: extern func -> Int

__STATE := Time microtime()
srand(__STATE)

Random: class {
    state := static __STATE
    
    random: static func -> Int {
        return rand()
    }

    randInt: static func(start, end: Int) -> Int {
        return randRange(start, end+1)
    }
    
    randInt: static func ~exclude(start, end: Int, ex: List<Int>) -> Int {
        return exclude(start, end, ex, randInt)
    }

    randRange: static func(start, end: Int) -> Int {
        width := end - start
        return start + (random() % width)
    }

    randRange: static func ~exclude(start, end: Int, ex: List<Int>) -> Int {
        return exclude(start, end, ex, randRange)
    }
    
    choice: static func <T> (l: List<T>) -> T {
        return l get(randRange(0, l size()))
    }

    exclude: static func(start, end: Int, ex: List<Int>, f: Func (Int, Int) -> Int) -> Int {
        toRet := f(start, end)
        while (ex contains(toRet)) {
            toRet = f(start, end)
        }
        return toRet
    }
    
    // Code taken from "http://software.intel.com/en-us/articles/fast-random-number-generator-on-the-intel-pentiumr-4-processor/"
    fastRandom: static func() -> Int {
        This state = 214013 * This state+ 2531011
        return (This state>>16) & 0x7fff
    }

    fastRandInt: static func(start, end: Int) -> Int {
        return fastRandRange(start, end+1)
    }
    
    fastRandInt: static func ~exclude(start, end: Int, ex: List<Int>) -> Int {
        return exclude(start, end, ex, fastRandInt)
    }

    fastRandRange: static func(start, end: Int) -> Int {
        width := end - start
        return start + (fastRandom() % width)
    }

    fastRandRange: static func ~exclude(start, end: Int, ex: List<Int>) -> Int {
        return exclude(start, end, ex, fastRandRange)
    }
    
} 





