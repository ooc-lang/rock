
// summary: http://en.wikipedia.org/wiki/List_comprehension

// Haskell example:
// s = [ 2*x | x <- [0..], x^2 > 3 ]

// ooc haskell-like proposal?
s := [ 2*x | x <- (0..), x*x > 3 ]
// equivalent to the following? (using notations in other proposals)
s := ListComprehension<Int> new(|x| 2*x, (0..), |x| x*x > 3)

ListComprehension: class <T> implements List<T> {
    
    output:    Func (T) -> T
    inputSet:  Range
    predicate: Func (T) -> Bool
    
    init: func (=output, =inputSet, =predicate) {}
    
    // hmm.
    get: func (i: Int) -> T {
        val := inputSet[i] // throw an error if no more values? dunno.
        if(predicate(val)) return output(val)
    }
    
}

// modifications needed to range literal syntax: allow (0..) to mean from 0 to infinity.
// what about arbitrary precision ranges?
