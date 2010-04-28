
#ifndef ___lang_array___
#define ___lang_array___

#define _lang_array__Array_new(type, size) { size, malloc(size * sizeof(type)) };

#define _lang_array__Array_get(array, index, type) ( \
    (index < 0 || index >= array.length) ? \
    printf("when reading from array index = %d out of bounds [0, %d)\n", index, array.length), exit(1), *((type*) NULL) : \
    ((type* restrict) array.data)[index])
    
#define _lang_array__Array_set(array, index, type, value) \
    if(index < 0 || index >= array.length) { \
        printf("when writing to array, index = %d out of bounds [0, %d)\n", index, array.length); \
        exit(1); \
    } \
    ((type* restrict) array.data)[index] = value;

typedef struct {
    int length;
    void* restrict data;
} _lang_array__Array;

#endif // ___lang_array___

