// Test zdolności: czy moduł PKCS#11 PWPW sam zestawi PACE po podaniu CAN przez C_SetCAN.
// CAN podawany WYŁĄCZNIE jako argv[1] w czasie uruchomienia — nie jest nigdzie zapisany.
#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
typedef unsigned char CK_BYTE; typedef unsigned long CK_ULONG; typedef CK_ULONG CK_RV; typedef CK_ULONG CK_SLOT_ID;
typedef struct { void*cm; void*dm; void*lm; void*um; CK_ULONG flags; void*res; } INIT_ARGS;
int main(int argc, char** argv){
  if(argc<3){ fprintf(stderr,"uzycie: %s <modul.dylib> <CAN>\n", argv[0]); return 2; }
  const char* can = argv[2]; CK_ULONG canlen = strlen(can);
  void* h = dlopen(argv[1], RTLD_NOW); if(!h){ fprintf(stderr,"dlopen: %s\n", dlerror()); return 3; }
  CK_RV(*C_Initialize)(void*) = dlsym(h,"C_Initialize");
  CK_RV(*C_GetSlotList)(CK_BYTE,CK_SLOT_ID*,CK_ULONG*) = dlsym(h,"C_GetSlotList");
  CK_RV(*C_GetTokenInfo)(CK_SLOT_ID,void*) = dlsym(h,"C_GetTokenInfo");
  CK_RV(*C_SetCAN)(CK_SLOT_ID,CK_BYTE*,CK_ULONG) = dlsym(h,"C_SetCAN");
  CK_RV(*C_Finalize)(void*) = dlsym(h,"C_Finalize");
  if(!C_Initialize||!C_GetSlotList||!C_GetTokenInfo||!C_SetCAN){ fprintf(stderr,"brak symbolu\n"); return 4; }
  INIT_ARGS ia; memset(&ia,0,sizeof ia); ia.flags=2; // CKF_OS_LOCKING_OK
  CK_RV rv=C_Initialize(&ia); printf("C_Initialize rv=0x%lx\n", rv);
  CK_SLOT_ID slots[16]; CK_ULONG n=16; rv=C_GetSlotList(0,slots,&n); printf("C_GetSlotList(all) rv=0x%lx slotow=%lu\n", rv, n);
  if(n==0){ printf("brak slotu (czytnik?)\n"); return 5; }
  CK_SLOT_ID slot=slots[0];
  unsigned char tok1[1024]; memset(tok1,0,sizeof tok1);
  rv=C_GetTokenInfo(slot,tok1); printf("PRZED C_SetCAN: C_GetTokenInfo rv=0x%lx (0xe0=CKR_TOKEN_NOT_PRESENT)\n", rv);
  rv=C_SetCAN(slot,(CK_BYTE*)can,canlen); printf("C_SetCAN(len=%lu) rv=0x%lx\n", canlen, rv);
  unsigned char tok2[1024]; memset(tok2,0,sizeof tok2);
  rv=C_GetTokenInfo(slot,tok2); printf("PO C_SetCAN:  C_GetTokenInfo rv=0x%lx\n", rv);
  if(rv==0){ char lbl[33]; memcpy(lbl,tok2,32); lbl[32]=0; printf("  token label: '%s'\n", lbl); }
  CK_ULONG m=16; rv=C_GetSlotList(1,slots,&m); printf("C_GetSlotList(token_present) rv=0x%lx tokenow=%lu\n", rv, m);
  if(C_Finalize) C_Finalize(0);
  return 0;
}
