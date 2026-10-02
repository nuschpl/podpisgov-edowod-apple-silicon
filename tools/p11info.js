// Informacje o tokenach e-dowodu BEZ logowania: długości PIN-u, flagi prób, certyfikaty.
var W = Packages.sun.security.pkcs11.wrapper, C = W.PKCS11Constants;
var a = new W.CK_C_INITIALIZE_ARGS(); a.flags = C.CKF_OS_LOCKING_OK;
var p = W.PKCS11.getInstance(arguments[0], "C_GetFunctionList", a, false);
function s(x){ return new java.lang.String(new java.lang.String(x).getBytes("ISO-8859-1"), "UTF-8").trim(); }
var F = {LOGIN_REQUIRED:0x4, PROTECTED_AUTH_PATH:0x100, USER_PIN_INITIALIZED:0x8, USER_PIN_COUNT_LOW:0x10000, USER_PIN_FINAL_TRY:0x20000, USER_PIN_LOCKED:0x40000, USER_PIN_TO_BE_CHANGED:0x80000, SO_PIN_LOCKED:0x400000};
var slots = p.C_GetSlotList(true);
if (slots.length == 0) print("Brak karty na czytniku — połóż e-dowód na czytniku i spróbuj ponownie.");
for (var i = 0; i < slots.length; i++) {
  var t = p.C_GetTokenInfo(slots[i]), fl = [];
  for (var k in F) if (t.flags & F[k]) fl.push(k);
  print("\nslot " + slots[i] + ": " + s(t.label));
  print("  PIN: min " + t.ulMinPinLen + ", max " + t.ulMaxPinLen + "   flagi: " + fl.join(", "));
  var h = p.C_OpenSession(slots[i], C.CKF_SERIAL_SESSION, null, null);
  var tpl = [new W.CK_ATTRIBUTE(C.CKA_CLASS, C.CKO_CERTIFICATE)];
  p.C_FindObjectsInit(h, tpl); var objs = p.C_FindObjects(h, 20); p.C_FindObjectsFinal(h);
  for (var j = 0; j < objs.length; j++) {
    var at = [new W.CK_ATTRIBUTE(C.CKA_LABEL), new W.CK_ATTRIBUTE(C.CKA_VALUE)];
    p.C_GetAttributeValue(h, objs[j], at);
    var cert = java.security.cert.CertificateFactory.getInstance("X.509").generateCertificate(new java.io.ByteArrayInputStream(at[1].getByteArray()));
    print("  cert: " + (at[0].pValue ? s(at[0].getCharArray()) : "?") + " | wystawca: " + cert.getIssuerX500Principal().getName().replace(/.*CN=([^,]+).*/, "$1") + " | ważny do " + cert.getNotAfter());
  }
  if (objs.length == 0) print("  (brak publicznych certyfikatów)");
  p.C_CloseSession(h);
}
