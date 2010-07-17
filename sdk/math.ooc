include math
use math

PI := 3.14159_26535_89793_23846_26433_83279

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

Double: cover {
    cos: extern(cos) func -> This
    sin: extern(sin) func -> This
    tan: extern(tan) func -> This
    acos: extern(acos) func -> This
    asin: extern(asin) func -> This
    atan: extern(atan) func -> This
    atan2: extern(atan2) func (This) -> This

    sqrt: extern(sqrt) func -> This
    pow: extern(pow) func (This) -> This
    
    log: extern(log) func -> This
    log10: extern(log10) func -> This

    round: extern(lround) func -> Long
    ceil: extern(ceil) func -> This
    floor: extern(floor) func -> This
}

Float: cover {
    cos: extern(cosf) func -> This
    sin: extern(sinf) func -> This
    tan: extern(tanf) func -> This
    acos: extern(acosf) func -> This
    asin: extern(asinf) func -> This
    atan: extern(atanf) func -> This
    atan2: extern(atan2f) func (This) -> This

    sqrt: extern(sqrtf) func -> This
    pow: extern(powf) func (This) -> This
    
    log: extern(logf) func -> This
    log10: extern(log10f) func -> This

    round: extern(lroundf) func -> Long
    ceil: extern(ceilf) func -> This
    floor: extern(floorf) func -> This
}

LDouble: cover {
    cos: extern(cosl) func -> This
    sin: extern(sinl) func -> This
    tan: extern(tanl) func -> This
    acos: extern(acosl) func -> This
    asin: extern(asinl) func -> This
    atan: extern(atanl) func -> This
    atan2: extern(atan2l) func (This) -> This

    sqrt: extern(sqrtl) func -> This
    pow: extern(powl) func (This) -> This
    
    log: extern(logl) func -> This
    log10: extern(log10l) func -> This

    round: extern(lroundl) func -> Long
    ceil: extern(ceill) func -> This
    floor: extern(floorl) func -> This
}