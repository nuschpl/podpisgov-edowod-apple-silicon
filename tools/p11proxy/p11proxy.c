/*
 * p11proxy — logujący moduł pośredniczący PKCS#11.
 *
 * Ładuje prawdziwy moduł (P11PROXY_TARGET, domyślnie /Users/Shared/PodpisGOV-x64/e-dowod-pkcs11-64.dylib),
 * przekazuje mu wszystkie wywołania i zapisuje do pliku (P11PROXY_LOG, domyślnie /tmp/p11proxy.log)
 * argumenty wejściowe i wyniki wybranych funkcji. Nie loguje PIN-ów (C_Login loguje tylko długość).
 *
 * Kompilacja (x86_64, bo moduł PWPW jest tylko x86_64):
 *   clang -arch x86_64 -dynamiclib -O1 -o p11proxy.dylib p11proxy.c
 */
#include <dlfcn.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <sys/time.h>

typedef unsigned long CK_ULONG, CK_RV, CK_SLOT_ID, CK_SESSION_HANDLE, CK_OBJECT_HANDLE, CK_ATTRIBUTE_TYPE, CK_FLAGS;
typedef unsigned char CK_BYTE, CK_BBOOL;
typedef struct { CK_ATTRIBUTE_TYPE type; void *pValue; CK_ULONG ulValueLen; } CK_ATTRIBUTE;
typedef struct { CK_BYTE major, minor; } CK_VERSION;

#define NFUNC 68 /* liczba funkcji w CK_FUNCTION_LIST v2.x */
typedef struct { CK_VERSION version; void *f[NFUNC]; } CK_FUNCTION_LIST;
enum { I_Initialize = 0, I_Finalize = 1, I_GetSlotList = 4, I_GetTokenInfo = 6, I_OpenSession = 12, I_Login = 18,
       I_GetAttributeValue = 24, I_FindObjectsInit = 26, I_FindObjects = 27, I_FindObjectsFinal = 28 };

static CK_FUNCTION_LIST *real, mine;
static FILE *lg;
static pthread_mutex_t mu = PTHREAD_MUTEX_INITIALIZER;

static void L(const char *fmt, ...) {
    pthread_mutex_lock(&mu);
    if (!lg) { const char *p = getenv("P11PROXY_LOG"); lg = fopen(p ? p : "/tmp/p11proxy.log", "a"); }
    if (lg) {
        struct timeval tv; gettimeofday(&tv, NULL);
        fprintf(lg, "%ld.%03d [%p] ", (long)tv.tv_sec % 100000, (int)(tv.tv_usec / 1000), (void *)pthread_self());
        va_list ap; va_start(ap, fmt); vfprintf(lg, fmt, ap); va_end(ap);
        fputc('\n', lg); fflush(lg);
    }
    pthread_mutex_unlock(&mu);
}

static const char *aname(CK_ULONG t) {
    switch (t) {
        case 0x0: return "CLASS"; case 0x1: return "TOKEN"; case 0x2: return "PRIVATE"; case 0x3: return "LABEL";
        case 0x11: return "VALUE"; case 0x80: return "CERTIFICATE_TYPE"; case 0x81: return "ISSUER"; case 0x82: return "SERIAL_NUMBER";
        case 0x101: return "SUBJECT"; case 0x102: return "ID"; case 0x100: return "KEY_TYPE"; case 0x86: return "TRUSTED";
        default: return "?";
    }
}

#define REAL(i, T) ((T)real->f[i])

static CK_RV P_Initialize(void *args) {
    CK_RV rv = REAL(I_Initialize, CK_RV (*)(void *))(args);
    L("C_Initialize(args=%p%s) -> 0x%lx", args, args ? "" : " NULL", rv);
    return rv;
}
static CK_RV P_GetSlotList(CK_BBOOL tp, CK_SLOT_ID *list, CK_ULONG *cnt) {
    CK_ULONG in = cnt ? *cnt : 0;
    CK_RV rv = REAL(I_GetSlotList, CK_RV (*)(CK_BBOOL, CK_SLOT_ID *, CK_ULONG *))(tp, list, cnt);
    L("C_GetSlotList(tokenPresent=%d, list=%p, cnt_in=%lu) -> 0x%lx cnt_out=%lu", tp, (void *)list, in, rv, cnt ? *cnt : 0);
    return rv;
}
static CK_RV P_OpenSession(CK_SLOT_ID s, CK_FLAGS fl, void *app, void *notify, CK_SESSION_HANDLE *h) {
    CK_RV rv = REAL(I_OpenSession, CK_RV (*)(CK_SLOT_ID, CK_FLAGS, void *, void *, CK_SESSION_HANDLE *))(s, fl, app, notify, h);
    L("C_OpenSession(slot=%lu, flags=0x%lx, notify=%p) -> 0x%lx h=%lu", s, fl, notify, rv, h ? *h : 0);
    return rv;
}
static CK_RV P_Login(CK_SESSION_HANDLE h, CK_ULONG ut, CK_BYTE *pin, CK_ULONG len) {
    CK_RV rv = REAL(I_Login, CK_RV (*)(CK_SESSION_HANDLE, CK_ULONG, CK_BYTE *, CK_ULONG))(h, ut, pin, len);
    L("C_Login(h=%lu, userType=%lu, pinLen=%lu [PIN nie jest logowany]) -> 0x%lx", h, ut, len, rv);
    return rv;
}
static CK_RV P_FindObjectsInit(CK_SESSION_HANDLE h, CK_ATTRIBUTE *t, CK_ULONG n) {
    CK_RV rv = REAL(I_FindObjectsInit, CK_RV (*)(CK_SESSION_HANDLE, CK_ATTRIBUTE *, CK_ULONG))(h, t, n);
    char b[512] = ""; size_t o = 0;
    for (CK_ULONG i = 0; i < n && o < sizeof b - 64; i++) {
        CK_ULONG v = (t[i].pValue && t[i].ulValueLen == sizeof(CK_ULONG)) ? *(CK_ULONG *)t[i].pValue : (CK_ULONG)-1;
        o += snprintf(b + o, sizeof b - o, " %s(0x%lx) len=%lu val=%ld;", aname(t[i].type), t[i].type, t[i].ulValueLen, (long)v);
    }
    L("C_FindObjectsInit(h=%lu, n=%lu:%s) -> 0x%lx", h, n, b, rv);
    return rv;
}
static CK_RV P_FindObjects(CK_SESSION_HANDLE h, CK_OBJECT_HANDLE *objs, CK_ULONG max, CK_ULONG *cnt) {
    CK_RV rv = REAL(I_FindObjects, CK_RV (*)(CK_SESSION_HANDLE, CK_OBJECT_HANDLE *, CK_ULONG, CK_ULONG *))(h, objs, max, cnt);
    char b[256] = ""; size_t o = 0;
    for (CK_ULONG i = 0; cnt && i < *cnt && o < sizeof b - 24; i++) o += snprintf(b + o, sizeof b - o, " %lu", objs[i]);
    L("C_FindObjects(h=%lu, max=%lu) -> 0x%lx cnt=%lu [%s ]", h, max, rv, cnt ? *cnt : 0, b);
    return rv;
}
static CK_RV P_GetAttributeValue(CK_SESSION_HANDLE h, CK_OBJECT_HANDLE obj, CK_ATTRIBUTE *t, CK_ULONG n) {
    CK_ATTRIBUTE in[32]; CK_ULONG m = n < 32 ? n : 32;
    memcpy(in, t, m * sizeof *t);
    CK_RV rv = REAL(I_GetAttributeValue, CK_RV (*)(CK_SESSION_HANDLE, CK_OBJECT_HANDLE, CK_ATTRIBUTE *, CK_ULONG))(h, obj, t, n);
    L("C_GetAttributeValue(h=%lu, obj=%lu, n=%lu) -> 0x%lx", h, obj, n, rv);
    for (CK_ULONG i = 0; i < m; i++) {
        long outlen = (long)t[i].ulValueLen;
        L("    [%lu] %-16s IN pValue=%-14p len=%-6lu  OUT pValue=%-14p len=%ld%s",
          i, aname(in[i].type), in[i].pValue, in[i].ulValueLen, t[i].pValue, outlen,
          t[i].ulValueLen == (CK_ULONG)-1 ? " (CK_UNAVAILABLE_INFORMATION)" : "");
    }
    return rv;
}

CK_RV C_GetFunctionList(CK_FUNCTION_LIST **pp) {
    if (!real) {
        const char *tp = getenv("P11PROXY_TARGET");
        if (!tp) tp = "/Users/Shared/PodpisGOV-x64/e-dowod-pkcs11-64.dylib";
        void *h = dlopen(tp, RTLD_NOW | RTLD_LOCAL);
        if (!h) { L("dlopen(%s) FAILED: %s", tp, dlerror()); return 0x5; /* CKR_GENERAL_ERROR */ }
        CK_RV (*gfl)(CK_FUNCTION_LIST **) = (CK_RV (*)(CK_FUNCTION_LIST **))dlsym(h, "C_GetFunctionList");
        CK_RV rv = gfl(&real);
        L("=== p11proxy: target %s, C_GetFunctionList -> 0x%lx, version %d.%d ===", tp, rv, real->version.major, real->version.minor);
        if (rv) return rv;
        memcpy(&mine, real, sizeof mine);
        mine.f[I_Initialize] = (void *)P_Initialize;
        mine.f[I_GetSlotList] = (void *)P_GetSlotList;
        mine.f[I_OpenSession] = (void *)P_OpenSession;
        mine.f[I_Login] = (void *)P_Login;
        mine.f[I_FindObjectsInit] = (void *)P_FindObjectsInit;
        mine.f[I_FindObjects] = (void *)P_FindObjects;
        mine.f[I_GetAttributeValue] = (void *)P_GetAttributeValue;
    }
    *pp = &mine;
    return 0;
}
