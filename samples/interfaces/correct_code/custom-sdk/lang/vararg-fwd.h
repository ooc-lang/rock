/* lang/vararg header-forward file, generated with rock, the ooc compiler written in ooc */

#ifndef __lang_vararg_fwd__
#define __lang_vararg_fwd__

#include <stdarg.h>

typedef va_list lang__VaList;
struct _lang__VaListClass;
typedef struct _lang__VaListClass lang__VaListClass;

#include <custom-sdk/lang/stdio-fwd.h>
#include <custom-sdk/lang/types.h>
#include <custom-sdk/lang/math-fwd.h>
#include <custom-sdk/lang/memory-fwd.h>
#include <custom-sdk/lang/system-fwd.h>
lang__VaListClass *VaList_class();

#endif // __lang_vararg_fwd__
