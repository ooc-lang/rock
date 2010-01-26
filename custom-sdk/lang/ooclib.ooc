include stdlib, stdint, stdbool, math, stdarg, memory, string

// variable arguments
VaList: cover from va_list
va_start: extern func (VaList, ...) // ap, last_arg
va_arg: extern func (VaList, ...) // ap, type
va_end: extern func (VaList) // ap

exit: extern func (Int)

// math
cos: extern func (Double) -> Double
sin: extern func (Double) -> Double
tan: extern func (Double) -> Double

acos: extern func (Double) -> Double
asin: extern func (Double) -> Double
atan: extern func (Double) -> Double

atan2: extern func (Double, Double) -> Double

sqrt: extern func (Double) -> Double
pow: extern func (Double, Double) -> Double

srand: extern func(Int)
rand: extern func -> Int

log: extern (log) func ~Double (Double) -> Double
log: extern (logf) func ~Float (Float) -> Float
log: extern (logl) func ~Long (LDouble) -> LDouble

log10: extern (log10) func ~Double (Double) -> Double
log10: extern (log10f) func ~Float (Float) -> Float
log10: extern (log10l) func ~Long (LDouble) -> LDouble

round: extern (lround) func ~dl (Double) -> Long

// memory management
sizeof: extern func (...) -> SizeT
memset: extern func (Pointer, Int, SizeT) -> Pointer
memcmp: extern func (Pointer, Pointer, SizeT) -> Int
memmove: extern func (Pointer, Pointer, SizeT)
memcpy: extern func (Pointer, Pointer, SizeT)
