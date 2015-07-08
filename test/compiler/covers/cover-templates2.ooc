
// this test triggers a particular bug in old versions of rock
// where resolve orders is so that things don't get resolved properly.
// see https://github.com/fasterthanlime/rock/issues/887

use sam-assert

assignDone := false
pleaseDone := false

Something: cover template <T> {

    t: T

    init: func@ (=t)

    blah: func -> T {
        t2: T

        assign := func (t3: T) {
            assignDone = true
            t2 = t3
        }

        please(|t4|
            assign(t4)
        )

        t2
    }

    please: func (f: Func(T)) {
        pleaseDone = true
        f(t)
    }

}

describe("somewhat complicated cover template test", ||
    s := Something<Int> new(42)
    v := s blah()
    expect(42, v)
)

