#pragma once
#ifndef ___lang_array___
#define ___lang_array___

#ifdef __OOC_USE_GC__
#define array_malloc GC_malloc
#define array_free GC_free
#else
#define array_malloc(size) calloc(1, (size))
#define array_free free
#endif // GC

#include <stdint.h>


#define _lang_array__Array_new(type, size) ((_lang_array__Array) { size, array_malloc(size * sizeof(type)) });

#define _lang_array__Array_get(array, index, type) ( \
    (index < 0 || index >= array.length) ? \
    lang_Exception__Exception_throw((lang_Exception__Exception *) lang_Exception__OutOfBoundsException_new_noOrigin(index, array.length)), \
    *((type*) array.data) : \
    ((type*) array.data)[index])

#define _lang_array__Array_set(array, index, type, value) \
    (index < 0 || index >= array.length) ? \
    lang_Exception__Exception_throw((lang_Exception__Exception *) lang_Exception__OutOfBoundsException_new_noOrigin(index, array.length)), \
    *((type*) array.data) : \
    (((type*) array.data)[index] = value)

#define _lang_array__Array_free(array) { array_free(array.data) }

typedef struct {
    size_t length;
    void* data;
} _lang_array__Array;

#endif // ___lang_array___

