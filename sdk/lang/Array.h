
#ifndef ___lang_array___
#define ___lang_array___

#ifdef __OOC_USE_GC__
#define array_malloc GC_malloc
#define array_free GC_free
#else
#define array_malloc malloc
#define array_free free
#endif // GC

#include <stdint.h>

#define _lang_array__Array_new(type, size) ((_lang_array__Array) { size, array_malloc(size * sizeof(type)) });

#define _lang_array__Array_get(array, index, type) ( \
    (index < 0 || index >= array.length) ? \
    lang_Exception__Exception_throw(lang_Exception__Exception_new_originMsg((lang_types__Class*) (lang_String__String_class()), lang_String__String_format_str((lang_String__String*) (void*) lang_String__String_new_withCStrAndLength("when reading from array index = %d out of bounds [0, %d)\n", 100), index, array.length))), \
    *((type*) NULL) : \
    ((type* restrict) array.data)[index])

#define _lang_array__Array_set(array, index, type, value) \
    if(index < 0 || index >= array.length) { \
        lang_Exception__Exception_throw(lang_Exception__Exception_new_originMsg((lang_types__Class*) (lang_String__String_class()), lang_String__String_format_str((lang_String__String*) (void*) lang_String__String_new_withCStrAndLength("when reading from array index = %d out of bounds [0, %d)\n", 100), index, array.length))); \
        exit(1); \
    } \
    ((type* restrict) array.data)[index] = value;

#define _lang_array__Array_free(array) { array_free(array.data) }

typedef struct {
    size_t length;
    void* restrict data;
} _lang_array__Array;

#endif // ___lang_array___

