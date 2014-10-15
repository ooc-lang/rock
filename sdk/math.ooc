include math
use math

PI := 3.14159_26535_89793_23846_26433_83279

abs: extern func (Int) -> Int

cos: extern func (Double) -> Double
sin: extern func (Double) -> Double
tan: extern func (Double) -> Double

acos: extern func (Double) -> Double
asin: extern func (Double) -> Double
atan: extern func (Double) -> Double

atan2: extern func (Double, Double) -> Double

sqrt: extern func (Double) -> Double
pow: extern func (Double, Double) -> Double

log: extern(log) func ~Double (Double) -> Double
log: extern(logf) func ~Float (Float) -> Float
log: extern(logl) func ~Long (LDouble) -> LDouble

log10: extern(log10) func ~Double (Double) -> Double
log10: extern(log10f) func ~Float (Float) -> Float
log10: extern(log10l) func ~Long (LDouble) -> LDouble

round: extern(lround) func ~dl (Double) -> Long

ceil: extern(ceil) func ~Double (Double) -> Double
ceil: extern(ceilf) func ~Float (Float) -> Float
ceil: extern(ceill) func ~Long (LDouble) -> LDouble

floor: extern(floor) func ~Double (Double) -> Double
floor: extern(floorf) func ~Float (Float) -> Float
floor: extern(floorl) func ~Long (LDouble) -> LDouble

/* I don't think math.ooc should be a bunch of global functions,
   instead it should define a bunch of methods on the numeric
   classes. I'm going to write these methods but leave the existing
   functions alone for the sake of compatability.

   For future additions please define only methods and not the
   function versions to discourage use of the deprecated function
   versions.

   - Scott
 */

extend Double {
    cos: extern(cos) func -> This
    sin: extern(sin) func -> This
    tan: extern(tan) func -> This
    acos: extern(acos) func -> This
    asin: extern(asin) func -> This
    atan: extern(atan) func -> This
    cosh: extern(cosh) func -> This
    sinh: extern(sinh) func -> This
    tanh: extern(tanh) func -> This
    acosh: extern(acosh) func -> This
    asinh: extern(asinh) func -> This
    atanh: extern(atanh) func -> This
    atan2: extern(atan2) func (This) -> This

    sqrt: extern(sqrt) func -> This
    cbrt: extern(cbrt) func -> This
    abs: extern(fabs) func ~math -> This
    pow: extern(pow) func (This) -> This
    exp: extern(exp) func -> This

    log: extern(log) func -> This
    log10: extern(log10) func -> This

    mod: extern(fmod) func (This) -> This

    round: extern(round) func -> This
    roundLong: extern(lround) func -> Long
    roundLLong: extern(llround) func -> LLong
    ceil: extern(ceil) func -> This
    floor: extern(floor) func -> This
    truncate: extern(trunc) func -> This
}

extend Float {
    cos: extern(cosf) func -> This
    sin: extern(sinf) func -> This
    tan: extern(tanf) func -> This
    acos: extern(acosf) func -> This
    asin: extern(asinf) func -> This
    atan: extern(atanf) func -> This
    cosh: extern(coshf) func -> This
    sinh: extern(sinhf) func -> This
    tanh: extern(tanhf) func -> This
    acosh: extern(acoshf) func -> This
    asinh: extern(asinhf) func -> This
    atanh: extern(atanhf) func -> This
    atan2: extern(atan2f) func (This) -> This

    sqrt: extern(sqrtf) func -> This
    cbrt: extern(cbrtf) func -> This
    abs: extern(fabsf) func ~math -> This
    pow: extern(powf) func (This) -> This
    exp: extern(expf) func -> This

    log: extern(logf) func -> This
    log10: extern(log10f) func -> This

    mod: extern(fmodf) func (This) -> This

    round: extern(roundf) func -> This
    roundLong: extern(lroundf) func -> Long
    roundLLong: extern(llroundf) func -> LLong
    ceil: extern(ceilf) func -> This
    floor: extern(floorf) func -> This
    truncate: extern(truncf) func -> This
}

extend LDouble {
    cos: extern(cosl) func -> This
    sin: extern(sinl) func -> This
    tan: extern(tanl) func -> This
    acos: extern(acosl) func -> This
    asin: extern(asinl) func -> This
    atan: extern(atanl) func -> This
    cosh: extern(coshl) func -> This
    sinh: extern(sinhl) func -> This
    tanh: extern(tanhl) func -> This
    acosh: extern(acoshl) func -> This
    asinh: extern(asinhl) func -> This
    atanh: extern(atanhl) func -> This
    atan2: extern(atan2l) func (This) -> This

    sqrt: extern(sqrtl) func -> This
    cbrt: extern(cbrtl) func -> This
    abs: extern(fabsl) func ~math -> This
    pow: extern(powl) func (This) -> This
    exp: extern(expl) func -> This

    log: extern(logl) func -> This
    log10: extern(log10l) func -> This

    mod: extern(fmodl) func (This) -> This

    round: extern(roundl) func -> This
    roundLong: extern(lroundl) func -> Long
    roundLLong: extern(llroundl) func -> LLong
    ceil: extern(ceill) func -> This
    floor: extern(floorl) func -> This
    truncate: extern(truncl) func -> This
}
