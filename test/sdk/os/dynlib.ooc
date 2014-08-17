
import os/Dynlib

main: func {
    version (windows) {
        lib := Dynlib load("KERNEL32")

        if (!lib) {
            "Fail! Couldn't load library KERNEL32" println()
            exit(1)
        }

        cpiAddr := lib symbol("GetCurrentProcessId")

        cpi := (cpiAddr, null) as Func () -> ULong

        "GetCurrentProcessId = %d" printfln(cpi())

        lib close()
    } else {
        lib := Dynlib load("libm")

        if (!lib) {
            "Fail! Couldn't load library libm" println()
            exit(1)
        }

        cosAddr := lib symbol("cos")

        cos := (cosAddr, null) as Func (Double) -> Double

        "cos(PI / 4) = %.3f" printfln(cos(3.14 * 0.25))

        lib close()
    }
}

