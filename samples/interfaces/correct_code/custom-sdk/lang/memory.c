/* lang/memory source file, generated with rock, the ooc compiler written in ooc */

#include "memory.h"


lang__Pointer gc_calloc(lang__SizeT nmemb, lang__SizeT size) {
    return GC_MALLOC(nmemb * size);
}
