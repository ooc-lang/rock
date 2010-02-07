/* 001-pure-ooc-slembcke header-forward file, generated with rock, the ooc compiler written in ooc */

#ifndef __001_pure_ooc_slembcke_fwd__
#define __001_pure_ooc_slembcke_fwd__

struct _KillableInterface;
typedef struct _KillableInterface KillableInterface;
typedef struct _KillableReference KillableReference;
struct _KillableDog;
typedef struct _KillableDog KillableDog;
struct _Dog;
typedef struct _Dog Dog;
struct _KillableInterfaceClass;
typedef struct _KillableInterfaceClass KillableInterfaceClass;
struct _KillableReferenceClass;
typedef struct _KillableReferenceClass KillableReferenceClass;
struct _KillableDogClass;
typedef struct _KillableDogClass KillableDogClass;
struct _DogClass;
typedef struct _DogClass DogClass;

#include <custom-sdk/lang/stdio-fwd.h>
#include <custom-sdk/lang/types.h>
#include <custom-sdk/lang/math-fwd.h>
#include <custom-sdk/lang/memory-fwd.h>
#include <custom-sdk/lang/system-fwd.h>
#include <custom-sdk/lang/vararg-fwd.h>
KillableInterfaceClass *KillableInterface_class();
KillableInterface* KillableInterface_new();
void KillableInterface_init(KillableInterface* this);
void KillableInterface_init_impl(KillableInterface* this);
lang__String KillableInterface_dyingNoise(KillableReference this);
KillableReferenceClass *KillableReference_class();
KillableDogClass *KillableDog_class();
KillableDog* KillableDog_new();
void KillableDog_init(KillableDog* this);
void KillableDog_init_impl(KillableDog* this);
DogClass *Dog_class();
Dog* Dog_new();
void Dog_init(Dog* this);
void Dog_init_impl(Dog* this);
lang__String Dog_trap(Dog* this);
lang__String Dog_trap_impl(Dog* this);
lang__String Dog_dyingNoise(Dog* this);
lang__String Dog_dyingNoise_impl(Dog* this);

#endif // __001_pure_ooc_slembcke_fwd__
