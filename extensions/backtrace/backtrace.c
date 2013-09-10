/* 
 * Universal backtrace extension for rock
 *
 * Inspired by the work of:
 *   - Cloud Wu, 2010 (http://codingnow.com/)
 *
 * Use, modification and distribution are subject to the "New BSD License"
 * as listed at <http://www.opensource.org/licenses/bsd-license.php>.
*/

#define PACKAGE "universal-backtrace"
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

#define BUFFER_MAX (16*1024)

// -- begin cross-platform types --

#ifdef __MINGW32__
#ifdef __MINGW64__
#define address_t DWORD64
#else
#define address_t DWORD
#endif
#else
#define address_t void*
#endif // __MINGW32__

// -- end cross-platform types --

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

struct output_buffer {
    char * buf;
    size_t sz;
    size_t ptr;
};

static void output_init(struct output_buffer *ob, char * buf, size_t sz) {
    ob->buf = buf;
    ob->sz = sz;
    ob->ptr = 0;
    ob->buf[0] = '\0';
}

static void output_print(struct output_buffer *ob, const char * format, ...) {
    if (ob->sz == ob->ptr)
        return;
    ob->buf[ob->ptr] = '\0';
    va_list ap;
    va_start(ap,format);
    vsnprintf(ob->buf + ob->ptr , ob->sz - ob->ptr , format, ap);
    va_end(ap);

    ob->ptr = strlen(ob->buf + ob->ptr) + ob->ptr;
}

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

static int init_bfd_ctx(struct bfd_ctx *bc, const char * procname, struct output_buffer *ob) {
    bc->handle = NULL;
    bc->symbol = NULL;

    bfd *b = bfd_openr(procname, 0);
    if (!b) {
        output_print(ob,"Failed to open bfd from (%s)\n" , procname);
        return 1;
    }

    int r1 = bfd_check_format(b, bfd_object);
    int r2 = bfd_check_format_matches(b, bfd_object, NULL);
    int r3 = bfd_get_file_flags(b) & HAS_SYMS;

    if (!(r1 && r2 && r3)) {
        bfd_close(b);
        if (r1 == 0 || r2 == 0) {
            //output_print(ob,"Unknown binary format (%s)\n", procname, r1, r2, r3);
        } else {
            //output_print(ob,"No symbols in (%s)\n", procname, r1, r2, r3);
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
        //output_print(ob,"Failed to read symbols from (%s)\n", procname);
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

static struct bfd_ctx * get_bc(struct output_buffer *ob , struct bfd_set *set , const char *procname) {
    while(set->name) {
        if (strcmp(set->name , procname) == 0) {
            return set->bc;
        }
        set = set->next;
    }
    struct bfd_ctx bc;
    if (init_bfd_ctx(&bc, procname , ob)) {
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

#ifdef __MINGW32__
static void _backtrace(struct output_buffer *ob, struct bfd_set *set, int depth , LPCONTEXT context) {
    char procname[MAX_PATH];
    GetModuleFileNameA(NULL, procname, sizeof procname);

    struct bfd_ctx *bc = NULL;

#ifdef __MINGW64__
    STACKFRAME64 frame;
    memset(&frame,0,sizeof(frame));

    frame.AddrPC.Offset = context->Rip;
    frame.AddrPC.Mode = AddrModeFlat;
    frame.AddrStack.Offset = context->Rsp;
    frame.AddrStack.Mode = AddrModeFlat;
    frame.AddrFrame.Offset = context->Rbp;
    frame.AddrFrame.Mode = AddrModeFlat;
#else
    STACKFRAME frame;
    memset(&frame,0,sizeof(frame));

    frame.AddrPC.Offset = context->Eip;
    frame.AddrPC.Mode = AddrModeFlat;
    frame.AddrStack.Offset = context->Esp;
    frame.AddrStack.Mode = AddrModeFlat;
    frame.AddrFrame.Offset = context->Ebp;
    frame.AddrFrame.Mode = AddrModeFlat;
#endif

    HANDLE process = GetCurrentProcess();
    HANDLE thread = GetCurrentThread();

    char symbol_buffer[sizeof(IMAGEHLP_SYMBOL) + 255];
    char module_name_raw[MAX_PATH];

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


        --depth;
        if (depth < 0) {
            break;
        }

        IMAGEHLP_SYMBOL *symbol = (IMAGEHLP_SYMBOL *)symbol_buffer;
        symbol->SizeOfStruct = (sizeof *symbol) + 255;
        symbol->MaxNameLength = 254;

        address_t module_base = SymGetModuleBase(process, frame.AddrPC.Offset);

        const char * module_name = "[unknown module]";
        if (module_base && 
                GetModuleFileNameA((HINSTANCE)module_base, module_name_raw, MAX_PATH)) {
            module_name = module_name_raw;
            bc = get_bc(ob, set, module_name);
        }

        const char * file = NULL;
        const char * func = NULL;
        unsigned line = 0;

        if (bc) {
            find(bc,frame.AddrPC.Offset,&file,&func,&line);
        }

        if (file == NULL) {
            address_t dummy = 0;
            if (SymGetSymFromAddr(process, frame.AddrPC.Offset, &dummy, symbol)) {
                file = symbol->Name;
            }
            else {
                file = "[unknown file]";
            }
        }
        
        if (func == NULL) {
            output_print(ob,"%s | 0x%x | %s \n", 
                    module_name,
                    frame.AddrPC.Offset,
                    file);
        } else {
            output_print(ob,"%s | 0x%x | %s | %s | %d\n", 
                    module_name,
                    frame.AddrPC.Offset,
                    func,
                    file,
                    line);
        }
    }
}
#else // __MINGW32__
static void _backtrace(struct output_buffer *ob, struct bfd_set *set, int depth, void **frames, int numFrames) {
    int frameno = 0;
    Dl_info info;
    struct bfd_ctx *bc = NULL;

    while (frameno < numFrames) {
        void *address = frames[frameno];

        const char * module_name = "[unknown module]";
        int ret = dladdr(address, &info);

        if (ret != 0) {
          address_t module_base = (address_t) info.dli_fbase;
          module_name = info.dli_fname;

          const char * file = NULL;
          const char * func = NULL;
          unsigned line = 0;

          bc = get_bc(ob, set, module_name);
          if (bc) {
            address_t offset = (address_t) (address - module_base);
            //void *sym = info.dli_saddr;
            //fprintf(stderr, "\n\n>> Looking for line/no of symbol %s\n", info.dli_sname);
            //fprintf(stderr, "module base = %p, address = %p, offset = %p, symbol addr = %p\n", (void*) module_base, (void*) address, (void*) offset, (void*) sym);
            find(bc, address, &file, &func, &line);

            if (func == NULL) {
              // For dynamic libs we have to search with offset - wtf, but why not.
              //fprintf(stderr, "trying again with offset\n");
              find(bc, offset, &file, &func, &line);
            }
          }

          if (file == NULL) {
            // fall back on backtrace info
            file = info.dli_sname;
          }

          if (func == NULL) {
              output_print(ob,"%s | 0x%x | %s \n", 
                      module_name,
                      address,
                      file);
          } else {
              output_print(ob,"%s | 0x%x | %s | %s | %d\n", 
                      module_name,
                      address,
                      func,
                      file,
                      line);
          }
        }

        ++frameno;
    }
}
#endif // non-__MINGW32__

typedef void (*backtrace_callback)(void *, char *);
static backtrace_callback g_backtrace_callback = NULL;
static void *g_backtrace_context = NULL;

static char * g_output = NULL;
#ifdef __MINGW32__
static LPTOP_LEVEL_EXCEPTION_FILTER g_prev = NULL;
#endif // __MINGW32__

#ifdef __MINGW32__
static void collect_stacktrace(LPCONTEXT context) {
    struct output_buffer ob;
    output_init(&ob, g_output, BUFFER_MAX);

    if (!SymInitialize(GetCurrentProcess(), 0, TRUE)) {
        output_print(&ob,"Failed to init symbol context\n");
    } else {
        bfd_init();
        struct bfd_set *set = calloc(1, sizeof(*set));
        _backtrace(&ob, set, 128, context);
        release_set(set);

        SymCleanup(GetCurrentProcess());
    }
}
#else // __MINGW32__
static void collect_stacktrace(void) {
    struct output_buffer ob;
    output_init(&ob, g_output, BUFFER_MAX);

    void **buffer = malloc(sizeof(void*) * 128);
    int numEntries = backtrace(buffer, 128);
    //output_print(&ob, "backtrace returned %d entries\n", numEntries);
    
    // skip first, it's us!
    buffer += 1;
    numEntries -= 1;

    bfd_init();
    struct bfd_set *set = calloc(1, sizeof(*set));
    _backtrace(&ob, set, 128, buffer, numEntries);
    release_set(set);
}
#endif // non-__MINGW32__

static void output_stacktrace(void) {
    if (g_backtrace_callback) {
        g_backtrace_callback(g_output, g_backtrace_context);
    } else {
        fputs(g_output, stderr);
    }
}

#if __MINGW32__
static void print_stacktrace(LPCONTEXT context) {
    collect_stacktrace(context);
    output_stacktrace();
}
#else // __MINGW32__
static void print_stacktrace(void) {
    collect_stacktrace();
    output_stacktrace();
}
#endif // non-__MINGW32__

BACKTRACE_LIB void backtrace_register_callback(backtrace_callback cb, void *context) {
    g_backtrace_callback = cb;
    g_backtrace_context = context;
    return;
}

BACKTRACE_LIB void backtrace_unregister_callback(void) {
    g_backtrace_callback = NULL;
    g_backtrace_context = NULL;
    return;
}

#ifdef __MINGW32__

BACKTRACE_LIB char * backtrace_capture(void) {
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

    // and... collect the backtrace!
    collect_stacktrace(&context);

    // Return the stack trace!
    return g_output;
}

static LONG WINAPI exception_filter(LPEXCEPTION_POINTERS info) {
    print_stacktrace(info->ContextRecord);
    return EXCEPTION_EXECUTE_HANDLER;
}

static void backtrace_register(void) {
    if (g_output == NULL) {
        g_output = malloc(BUFFER_MAX);
        g_prev = SetUnhandledExceptionFilter(exception_filter);
    }
}

static void backtrace_unregister(void) {
    if (g_output) {
        free(g_output);
        SetUnhandledExceptionFilter(g_prev);
        g_prev = NULL;
        g_output = NULL;
    }
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD dwReason, LPVOID lpvReserved) {
    switch (dwReason) {
        case DLL_PROCESS_ATTACH:
            backtrace_register();
            break;
        case DLL_PROCESS_DETACH:
            backtrace_unregister();
            break;
    }
    return TRUE;
}
#else // __MINGW32__

BACKTRACE_LIB char * backtrace_capture(void) {
    // no magic needed outside Windows.
    collect_stacktrace();

    return g_output;
}

static void backtrace_signal_handler(int signo, siginfo_t *si, ucontext_t* context) {
    // debugging.
    print_stacktrace();
    exit(1);
}

static void backtrace_error_handler(char *format, ...) {
    // mostly used for unrecognized load commands - ignore that.
}

void __attribute__((constructor)) backtrace_constructor (void) {
    if (g_output == NULL) {
        g_output = malloc(BUFFER_MAX);
    }

    // catch BFD errors (if not set, will go to stderr)
    bfd_set_error_handler((void*) backtrace_error_handler);

    // catch a few signals
    signal(SIGSEGV, (void*) backtrace_signal_handler);
    signal(SIGABRT, (void*) backtrace_signal_handler);
    signal(SIGBUS,  (void*) backtrace_signal_handler);
    signal(SIGFPE,  (void*) backtrace_signal_handler);
    signal(SIGILL,  (void*) backtrace_signal_handler);
    signal(SIGPIPE, (void*) backtrace_signal_handler);
}

#endif // non-__MINGW32__

