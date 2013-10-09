
import os/Dynlib

main: func {
    lib := Dynlib load("libm")

    if (!lib) {
        raise("Couldn't load library!")
    }

    cosAddr := lib symbol("cos")

    cos := (cosAddr, null) as Func (Double) -> Double

    "cos(PI / 4) = %.3f" printfln(cos(3.14 * 0.25))

    lib close()
}

