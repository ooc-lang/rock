/* lang/stdio header file, generated with rock, the ooc compiler written in ooc */

#ifndef __lang_stdio__
#define __lang_stdio__

#include "stdio-fwd.h"

struct _lang__FILE {
};

struct _lang__FILEClass {
    struct _lang__ClassClass __super__;
};


struct _lang__FStreamClass {
    struct _lang__ClassClass __super__;
    lang__Char (*readChar)(lang__FStream);
    lang__String (*readLine)(lang__FStream);
    lang__Bool (*hasNext)(lang__FStream);
    void (*write_chr)(lang__FStream, lang__Char);
    void (*write)(lang__FStream, lang__String);
    lang__SizeT (*write_precise)(lang__FStream, lang__Char*, lang__SizeT, lang__SizeT);
};


void println();

#endif // __lang_stdio__
