/* lang/stdio header-forward file, generated with rock, the ooc compiler written in ooc */

#ifndef __lang_stdio_fwd__
#define __lang_stdio_fwd__

#include <stdio.h>

typedef struct _lang__FILE lang__FILE;
typedef FILE* lang__FStream;
struct _lang__FILEClass;
typedef struct _lang__FILEClass lang__FILEClass;
struct _lang__FStreamClass;
typedef struct _lang__FStreamClass lang__FStreamClass;

#include <custom-sdk/lang/types.h>
#include <custom-sdk/lang/math-fwd.h>
#include <custom-sdk/lang/memory-fwd.h>
#include <custom-sdk/lang/system-fwd.h>
#include <custom-sdk/lang/vararg-fwd.h>
lang__FILEClass *FILE_class();
lang__FStreamClass *FStream_class();
lang__Char FStream_readChar(lang__FStream this);
lang__String FStream_readLine(lang__FStream this);
lang__Bool FStream_hasNext(lang__FStream this);
void FStream_write_chr(lang__FStream this, lang__Char chr);
void FStream_write(lang__FStream this, lang__String str);
lang__SizeT FStream_write_precise(lang__FStream this, lang__Char* str, lang__SizeT offset, lang__SizeT length);

#endif // __lang_stdio_fwd__
