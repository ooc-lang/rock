/* lang/stdio source file, generated with rock, the ooc compiler written in ooc */

#include "stdio.h"


lang__FILEClass *FILE_class(){
    static lang__Bool __done__ = false;
    static lang__FILEClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__FILE),
                    .size = sizeof(void*),
                    .name = "FILE",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

lang__Char FStream_readChar(lang__FStream this) {
    lang__Char c;
    fread(&(c), 1, 1, this);
    return c;
}

lang__String FStream_readLine(lang__FStream this) {
    lang__Int chunk = 128;
    lang__Int length = chunk;
    lang__Int pos = 0;
    lang__String str = ((lang__String) GC_MALLOC(length));
    fgets(str, chunk, this);
    while (String_last(str) != '\n') {
        pos += chunk - 1;
        length += chunk;
        lang__Pointer tmp = GC_REALLOC(str, length);
        str = tmp;
        fgets(((lang__Char*) str) + pos, chunk, this);
    }
    return str;
}

lang__Bool FStream_hasNext(lang__FStream this) {
    return feof(this) == 0;
}

void FStream_write_chr(lang__FStream this, lang__Char chr) {
    fputc(chr, this);
}

void FStream_write(lang__FStream this, lang__String str) {
    fputs(str, this);
}

lang__SizeT FStream_write_precise(lang__FStream this, lang__Char* str, lang__SizeT offset, lang__SizeT length) {
    return fwrite(str + offset, 1, length, this);
}

lang__FStreamClass *FStream_class(){
    static lang__Bool __done__ = false;
    static lang__FStreamClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__FStream),
                    .size = sizeof(void*),
                    .name = "FStream",
                },
                .__defaults__ = (void (*)(lang__Object*)) Object___defaults___impl,
                .__destroy__ = (void (*)(lang__Object*)) Object___destroy___impl,
            },
        },
    };
    lang__Class *classPtr = (lang__Class *) &class;
    if(!__done__){
        classPtr->super = (lang__Class*) Object_class();
        __done__ = true;
    }
    return &class;
}

void println() {
    printf("\n");
}
