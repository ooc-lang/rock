include stdlib

exit: extern func (Int)
atexit: extern func (Pointer)
include stdarg

// variable arguments
VaList: cover from va_list
va_start: extern func (VaList, ...) // ap, last_arg
va_arg: extern func (VaList, ...) // ap, type
va_end: extern func (VaList) // ap
va_copy: extern func(VaList, VaList) // dest, src
