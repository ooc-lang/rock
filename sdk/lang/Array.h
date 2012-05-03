#ifndef ___lang_array___
#define ___lang_array___

#include <stdint.h>

#define _lang_array__Array_new(type, size) ((_lang_array__Array) { size, GC_malloc(size * sizeof(type)) });

#define _lang_array__Array_get(array, index, type) ( \
    (index < 0 || index >= array.length) ? \
    lang_Exception__Exception_throw((lang_Exception__Exception *) lang_Exception__OutOfBoundsException_new_noOrigin(index, array.length)), \
    *((type*) NULL) : \
    ((type* restrict) array.data)[index])

#define _lang_array__Array_set(array, index, type, value) \
    (index < 0 || index >= array.length) ? \
    lang_Exception__Exception_throw((lang_Exception__Exception *) lang_Exception__OutOfBoundsException_new_noOrigin(index, array.length)), \
    *((type*) NULL) : \
    (((type* restrict) array.data)[index] = value)

#define _lang_array__Array_free(array) { GC_malloc_free(array.data) }

typedef struct {
    size_t length;
    void* restrict data;
} _lang_array__Array;

#endif

