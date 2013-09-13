/* 
 * Fancy backtrace extension for rock
 *
 * Mimics the interface of <execinfo.h> but with fancy_backtrace and
 * fancy_backtrace_symbols, giving additional information (source file, line
 * numbers) with pipe-separated values ready for further formatting.
 *
 * Also include fancy_backtrace_with_context on Windows, usable in response
 * to exceptions.
 *
 * Inspired by the work of:
 *   - Cloud Wu, 2010 (http://codingnow.com/)
 *
 * Use, modification and distribution are subject to the "New BSD License"
 * as listed at <http://www.opensource.org/licenses/bsd-license.php>.
*/

#define PACKAGE "fancy-backtrace"
#define PACKAGE_VERSION "2.0.0"

#ifdef __MINGW32__

// Windows (MinGW) specific headers
#include <windows.h>
#include <excpt.h>
#include <imagehlp.h>
#include <psapi.h>

#else

// Linux and OSX specific headers
#include <dlfcn.h>
#include <execinfo.h>
#include <signal.h>

#endif // __MINGW32__

#include <bfd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdbool.h>

/////////////////////////////////////////////////////
//
//  Build directives for .dll/.dylib/.so
//
/////////////////////////////////////////////////////

#ifdef __MINGW32__

#ifdef BUILDING_BACKTRACE_LIB
#define BACKTRACE_LIB __declspec(dllexport)
#else
#define BACKTRACE_LIB __declspec(dllimport)
#endif // BUILDING_BACKTRACE_LIB

#else // __MINGW32__

#ifdef BUILDING_BACKTRACE_LIB
#define BACKTRACE_LIB __attribute__((__visibility__("default"))) 
#else
#define BACKTRACE_LIB
#endif

#endif // non __MINGW32__

#define BUFFER_MAX 256

/////////////////////////////////////////////////////
//
//  Internal types
//
/////////////////////////////////////////////////////

#ifdef __MINGW32__
#ifdef __MINGW64__
#define address_t DWORD64
#else
#define address_t DWORD
#endif
#else
#define address_t void*
#endif // __MINGW32__

struct bfd_ctx {
    bfd * handle;
    asymbol ** symbol;
};

struct bfd_set {
    char * name;
    struct bfd_ctx * bc;
    struct bfd_set *next;
};

struct find_info {
    asymbol **symbol;
    bfd_vma counter;
    const char *file;
    const char *func;
    unsigned line;
};

/////////////////////////////////////////////////////
//
//  Convenience functions for libbfd usage
//
/////////////////////////////////////////////////////


static void lookup_section(bfd *abfd, asection *sec, void *opaque_data) {
    struct find_info *data = opaque_data;

    if (data->func)
        return;

    if (!(bfd_get_section_flags(abfd, sec) & SEC_ALLOC)) {
        return;
    }

    bfd_vma vma = bfd_get_section_vma(abfd, sec);
    bfd_vma size = bfd_get_section_size(sec);

    //fprintf(stderr, "Looking at %p (%lu bytes)\n", (void*) vma, (unsigned long) size);

    if (data->counter < vma || (vma + size) <= data->counter) {
        return;
    }

    //fprintf(stderr, "finding nearest line\n");
    bfd_find_nearest_line(abfd, sec, data->symbol, data->counter - vma, &(data->file), &(data->func), &(data->line));
}

static void find(struct bfd_ctx * b, address_t offset, const char **file, const char **func, unsigned *line) {
    struct find_info data;
    data.func = NULL;
    data.symbol = b->symbol;
    data.counter = (bfd_vma) offset;
    data.file = NULL;
    data.func = NULL;
    data.line = 0;

    bfd_map_over_sections(b->handle, &lookup_section, &data);
    if (file) {
        *file = data.file;
    }
    if (func) {
        *func = data.func;
    }
    if (line) {
        *line = data.line;
    }
}

static int init_bfd_ctx(struct bfd_ctx *bc, const char * procname) {
    bc->handle = NULL;
    bc->symbol = NULL;

    bfd *b = bfd_openr(procname, 0);
    if (!b) {
        fprintf(stderr, "Failed to open bfd from (%s)\n" , procname);
        return 1;
    }

    int r1 = bfd_check_format(b, bfd_object);
    int r2 = bfd_check_format_matches(b, bfd_object, NULL);
    int r3 = bfd_get_file_flags(b) & HAS_SYMS;

    if (!(r1 && r2 && r3)) {
        bfd_close(b);
        if (r1 == 0 || r2 == 0) {
            //fprintf(stderr, "Unknown binary format (%s)\n", procname, r1, r2, r3);
        } else {
            //fprintf(stderr, "No symbols in (%s)\n", procname, r1, r2, r3);
        }
        return 1;
    }

    void *symbol_table;

    unsigned dummy = 0;
    unsigned num_symbols = 0;

    num_symbols = bfd_read_minisymbols(b, FALSE, &symbol_table, &dummy);
    if (num_symbols == 0) {
      num_symbols = bfd_read_minisymbols(b, TRUE, &symbol_table, &dummy);
    }

    if (num_symbols < 0) {
        free(symbol_table);
        bfd_close(b);
        //fprintf(stderr, "Failed to read symbols from (%s)\n", procname);
        return 1;
    }

    //fprintf(stderr, "Successfully read %d symbols (%s)\n", num_symbols, procname);

    bc->handle = b;
    bc->symbol = symbol_table;

    return 0;
}

static void close_bfd_ctx(struct bfd_ctx *bc) {
    if (bc) {
        if (bc->symbol) {
            free(bc->symbol);
        }
        if (bc->handle) {
            bfd_close(bc->handle);
        }
    }
}

static struct bfd_ctx * get_bc(struct bfd_set *set , const char *procname) {
    while(set->name) {
        if (strcmp(set->name , procname) == 0) {
            return set->bc;
        }
        set = set->next;
    }
    struct bfd_ctx bc;
    if (init_bfd_ctx(&bc, procname)) {
        return NULL;
    }
    set->next = calloc(1, sizeof(*set));
    set->bc = malloc(sizeof(struct bfd_ctx));
    memcpy(set->bc, &bc, sizeof(bc));
    set->name = strdup(procname);

    return set->bc;
}

static void release_set(struct bfd_set *set) {
    while(set) {
        struct bfd_set * temp = set->next;
        free(set->name);
        close_bfd_ctx(set->bc);
        free(set);
        set = temp;
    }
}

/////////////////////////////////////////////////////
//
//  Error handlers, initializers
//
/////////////////////////////////////////////////////

static void backtrace_error_handler(char *format, ...) {
    // mostly used for unrecognized load commands - ignore that.
}

// constructor / destructor for all platforms:

static void fancy_backtrace_init(void) {
    // catch BFD errors (if not set, will go to stderr)
    bfd_set_error_handler((void*) backtrace_error_handler);
}

static void fancy_backtrace_free(void) {
    bfd_set_error_handler(NULL);
}

#ifdef __MINGW32__

// Windows has a clean entry point for DLLs

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD dwReason, LPVOID lpvReserved) {
    switch (dwReason) {
        case DLL_PROCESS_ATTACH:
            fancy_backtrace_init();
            break;
        case DLL_PROCESS_DETACH:
            fancy_backtrace_free();
            break;
    }
    return TRUE;
}

#else

// On Linux/OSX, use GCC attributes

void __attribute__((constructor)) backtrace_constructor (void) {
    fancy_backtrace_init();
}

void __attribute__((destructor)) backtrace_destructor (void) {
    fancy_backtrace_free();
}

#endif

/////////////////////////////////////////////////////
//
//  Public interface
//
/////////////////////////////////////////////////////

#ifdef __MINGW32__

BACKTRACE_LIB int fancy_backtrace_with_context (void **frames, int maxFrames, LPCONTEXT context) {

#ifdef __MINGW64__
    STACKFRAME64 frame;
#else
    STACKFRAME frame;
#endif

    memset(&frame,0,sizeof(frame));
    frame.AddrPC.Mode    = AddrModeFlat;
    frame.AddrStack.Mode = AddrModeFlat;
    frame.AddrFrame.Mode = AddrModeFlat;

#ifdef __MINGW64__
    frame.AddrPC.Offset    = context->Rip;
    frame.AddrStack.Offset = context->Rsp;
    frame.AddrFrame.Offset = context->Rbp;
#else
    frame.AddrPC.Offset    = context->Eip;
    frame.AddrStack.Offset = context->Esp;
    frame.AddrFrame.Offset = context->Ebp;
#endif

    HANDLE process = GetCurrentProcess();
    HANDLE thread = GetCurrentThread();
    int frameNo = 0;

    if (!SymInitialize(process, 0, TRUE)) {
        return 0;
    }

#ifdef __MINGW64__
    while(StackWalk64(IMAGE_FILE_MACHINE_AMD64, 
                process, 
                thread, 
                &frame, 
                context, 
                NULL, 
                SymFunctionTableAccess64, 
                SymGetModuleBase64, 0)) {
#else
    while(StackWalk(IMAGE_FILE_MACHINE_I386, 
                process, 
                thread, 
                &frame, 
                context, 
                NULL, 
                SymFunctionTableAccess, 
                SymGetModuleBase, 0)) {
#endif

        frames[frameNo++] = (void*) frame.AddrPC.Offset;

        if (frameNo >= maxFrames) {
            break;
        }
    }

    SymCleanup(process);

    return frameNo;
}

BACKTRACE_LIB int fancy_backtrace(void **frames, int maxFrames) {
    CONTEXT context;
    memset(&context, 0, sizeof(CONTEXT));

    context.ContextFlags = CONTEXT_CONTROL;

#ifdef __MINGW64__
    // there's a function for that!
    RtlCaptureContext(&context);
#else
    // no function available for 32-bit Windows, we have to
    // use inline assembly to retrieve the register values we need.
    void * reg_eip = NULL;
    __asm__ volatile ("1: movl $1b, %0" : "=r" (reg_eip));
    
    void * reg_esp = NULL;
    __asm__ volatile ("movl %%esp, %0" : "=r" (reg_esp));
    
    void * reg_ebp = NULL;
    __asm__ volatile ("movl %%ebp, %0" : "=r" (reg_ebp));

    // transfer them to the context
    context.Eip = (DWORD) reg_eip;
    context.Esp = (DWORD) reg_esp;
    context.Ebp = (DWORD) reg_ebp;
#endif

    // and... collect!
    return fancy_backtrace_with_context(frames, maxFrames, &context);
}

BACKTRACE_LIB char ** fancy_backtrace_symbols (void **frames, int numFrames) {

    HANDLE process = GetCurrentProcess();

    if (!SymInitialize(process, 0, TRUE)) {
        fprintf(stderr, "Failed to init symbol context\n");
        return NULL;
    }

    bfd_init();
    struct bfd_set *set = calloc(1, sizeof(*set));

    struct bfd_ctx *bc = NULL;
#ifdef __MINGW64__
    char symbol_buffer[sizeof(IMAGEHLP_SYMBOL64) + 255];
#else
    char symbol_buffer[sizeof(IMAGEHLP_SYMBOL) + 255];
#endif
    char module_name_raw[MAX_PATH];

    int frameNo = 0;
    char **result = malloc(sizeof(char*) * numFrames);

    while (frameNo < numFrames) {
        address_t addrOffset = (address_t) frames[frameNo];

#ifdef __MINGW64__
        IMAGEHLP_SYMBOL64 *symbol = (IMAGEHLP_SYMBOL64 *) symbol_buffer;
#else
        IMAGEHLP_SYMBOL *symbol = (IMAGEHLP_SYMBOL *) symbol_buffer;
#endif
        symbol->SizeOfStruct = (sizeof *symbol) + 255;
        symbol->MaxNameLength = 254;

#ifdef __MINGW64__
        address_t module_base = SymGetModuleBase64(process, addrOffset);
#else
        address_t module_base = SymGetModuleBase(process, addrOffset);
#endif

        const char * module_name = "[unknown module]";
        if (module_base && 
                GetModuleFileNameA((HINSTANCE)module_base, module_name_raw, MAX_PATH)) {
            module_name = module_name_raw;
            bc = get_bc(set, module_name);
        }

        const char * file = NULL;
        const char * func = NULL;
        unsigned line = 0;

        if (bc) {
            find(bc, addrOffset, &file, &func, &line);
        }

        if (file == NULL) {
            address_t dummy = 0;
#ifdef __MINGW64__
            if (SymGetSymFromAddr64(process, addrOffset, &dummy, symbol)) {
#else
            if (SymGetSymFromAddr(process, addrOffset, &dummy, symbol)) {
#endif
                file = symbol->Name;
            } else {
                file = "[unknown file]";
            }
        }
        
        char *output = malloc(BUFFER_MAX);
        if (func == NULL) {
            snprintf(output, BUFFER_MAX, "%s | 0x%p | %s", 
                    module_name,
                    (void *) addrOffset,
                    file);
        } else {
            snprintf(output, BUFFER_MAX, "%s | 0x%p | %s | %s | %d", 
                    module_name,
                    (void *) addrOffset,
                    func,
                    file,
                    line);
        }

        result[frameNo++] = output;
    }

    release_set(set);

    SymCleanup(process);

    return result;
}

#else // __MINGW32__

BACKTRACE_LIB int fancy_backtrace(void **frames, int maxFrames) {
    // from <execinfo.h>
    return backtrace(frames, maxFrames);
}

BACKTRACE_LIB char ** fancy_backtrace_symbols(void **frames, int numFrames) {
    bfd_init();
    struct bfd_set *set = calloc(1, sizeof(*set));

    Dl_info info;
    struct bfd_ctx *bc = NULL;

    int frameNo = 0;
    char **result = malloc(sizeof(char*) * numFrames);

    while (frameNo < numFrames) {
        address_t address = (address_t) frames[frameNo];

        const char * module_name = "[unknown module]";
        int ret = dladdr(address, &info);

        char *output = malloc(BUFFER_MAX);

        if (ret == 0) {

          // sorry, we don't know anything about it.
          output[0] = '\0';

        } else {

          address_t module_base = (address_t) info.dli_fbase;
          module_name = info.dli_fname;

          const char * file = NULL;
          const char * func = NULL;
          unsigned line = 0;

          bc = get_bc(set, module_name);
          if (bc) {
            address_t offset = (address_t) (address - module_base);
            find(bc, address, &file, &func, &line);

            if (func == NULL) {
              // For dynamic libs we have to search with offset - wtf, but why not.
              find(bc, offset, &file, &func, &line);
            }
          }

          if (file == NULL) {
            // fall back on backtrace info
            file = info.dli_sname;
          }

          if (func == NULL) {
              snprintf(output, BUFFER_MAX, "%s | 0x%p | %s", 
                      module_name,
                      address,
                      file);
          } else {
              snprintf(output, BUFFER_MAX, "%s | 0x%p | %s | %s | %d", 
                      module_name,
                      address,
                      func,
                      file,
                      line);
          }

        }

        result[frameNo++] = output;
    }

    release_set(set);

    return result;
}

#endif // non-__MINGW32__

