/* lang/vararg source file, generated with rock, the ooc compiler written in ooc */

#include "vararg.h"


lang__VaListClass *VaList_class(){
    static lang__Bool __done__ = false;
    static lang__VaListClass class = 
    {
        {
            {
                {
                    .instanceSize = sizeof(lang__VaList),
                    .size = sizeof(void*),
                    .name = "VaList",
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
