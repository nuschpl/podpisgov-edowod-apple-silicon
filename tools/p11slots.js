var W = Packages.sun.security.pkcs11.wrapper;
var init = new W.CK_C_INITIALIZE_ARGS(); init.flags = W.PKCS11Constants.CKF_OS_LOCKING_OK;
var p = W.PKCS11.getInstance(arguments[0], "C_GetFunctionList", init, false);
print("Library: " + p.C_GetInfo());
var all = p.C_GetSlotList(false), tok = p.C_GetSlotList(true);
print("Slots: " + all.length + ", with token: " + tok.length);
for (var i=0;i<all.length;i++){ var s=p.C_GetSlotInfo(all[i]); print(" slot "+all[i]+": "+String(new java.lang.String(s.slotDescription)).trim()+" flags="+s.flags);}
for (var i=0;i<tok.length;i++){ var t=p.C_GetTokenInfo(tok[i]); print(" token "+tok[i]+": label="+String(new java.lang.String(t.label)).trim()+" model="+String(new java.lang.String(t.model)).trim()+" flags=0x"+java.lang.Long.toHexString(t.flags));}
