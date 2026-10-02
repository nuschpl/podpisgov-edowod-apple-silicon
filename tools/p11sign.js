// Test podpisu jednym tokenem e-dowodu. PIN czytany przez System.console().readPassword
// (bez echa, nie przechodzi przez powłokę), sprawdzany lokalnie pod kątem długości,
// po użyciu zerowany. Podpisywane są losowe dane testowe, nie dokument.
var lib = arguments[0], slot = java.lang.Long.parseLong(arguments[1]);
var W = Packages.sun.security.pkcs11.wrapper, C = W.PKCS11Constants;
var a = new W.CK_C_INITIALIZE_ARGS(); a.flags = C.CKF_OS_LOCKING_OK;
var raw = W.PKCS11.getInstance(lib, "C_GetFunctionList", a, false);
var ti = raw.C_GetTokenInfo(slot);
var label = new java.lang.String(new java.lang.String(ti.label).getBytes("ISO-8859-1"), "UTF-8").trim();
var min = ti.ulMinPinLen, max = ti.ulMaxPinLen, fl = ti.flags;
print("\n=== " + label + " (slot " + slot + ") — PIN: " + min + (min == max ? "" : "–" + max) + " cyfr ===");
if (fl & 0x40000) { print("PIN ZABLOKOWANY — pomijam. Odblokowanie: kod PUK."); exit(2); }
if (fl & 0x20000) { print("KARTA ZGŁASZA OSTATNIĄ PRÓBĘ — pomijam, żeby nie zablokować PIN-u."); exit(2); }
if (fl & 0x10000) print("UWAGA: karta zgłasza, że była już błędna próba PIN-u.");
var con = java.lang.System.console();
if (con == null) { print("Brak terminala — uruchom skrypt bezpośrednio w Terminalu."); exit(3); }
var pin = con.readPassword("Wpisz PIN dla „%s” (Enter bez PIN-u = pomiń): ", label);
if (pin == null || pin.length == 0) { print("Pominięto."); exit(0); }
var digits = true; for (var i = 0; i < pin.length; i++) if (!java.lang.Character.isDigit(pin[i])) digits = false;
if (!digits || pin.length < min || pin.length > max) {
  java.util.Arrays.fill(pin, ' ');
  print("Odrzucono LOKALNIE: ten token przyjmuje " + min + (min == max ? "" : "–" + max) + " cyfr. PIN nie został wysłany do karty — próba nie przepadła.");
  exit(4);
}
var cfg = java.io.File.createTempFile("p11", ".cfg"); cfg.deleteOnExit();
var fw = new java.io.FileWriter(cfg); fw.write("name=Test" + slot + "\nlibrary=\"" + lib + "\"\nslot=" + slot + "\n"); fw.close();
var prov = new Packages.sun.security.pkcs11.SunPKCS11(cfg.getPath()); cfg["delete"]();
java.security.Security.addProvider(prov);
var ks = java.security.KeyStore.getInstance("PKCS11", prov);
try { ks.load(null, pin); }
catch (e) {
  java.util.Arrays.fill(pin, ' ');
  var m = String(e); var c = e; while (c.getCause && c.getCause()) c = c.getCause(); m += " / " + c;
  if (m.indexOf("CKR_PIN_INCORRECT") >= 0) print("BŁĘDNY PIN — karta odrzuciła PIN (jedna próba zużyta).");
  else if (m.indexOf("CKR_PIN_LOCKED") >= 0) print("PIN ZABLOKOWANY.");
  else print("Logowanie nieudane: " + m);
  exit(5);
}
java.util.Arrays.fill(pin, ' ');
print("PIN POPRAWNY — logowanie do tokenu udane.");
var al = ks.aliases(), n = 0;
while (al.hasMoreElements()) {
  var alias = al.nextElement();
  if (!ks.isKeyEntry(alias)) continue;
  var key = ks.getKey(alias, null), cert = ks.getCertificate(alias);
  var alg = String(key.getAlgorithm()) === "EC" ? "SHA256withECDSA" : "SHA256withRSA";
  var data = new java.security.SecureRandom().generateSeed(32);
  var sg = java.security.Signature.getInstance(alg, prov); sg.initSign(key); sg.update(data); var sig = sg.sign();
  var ok = "nie sprawdzono";
  if (cert) { var v = java.security.Signature.getInstance(alg); v.initVerify(cert.getPublicKey()); v.update(data); ok = v.verify(sig) ? "PODPIS POPRAWNY" : "PODPIS NIEPOPRAWNY"; }
  print("  klucz: " + alias + " | " + alg + " | " + ok);
  if (cert) print("  certyfikat wystawił: " + cert.getIssuerX500Principal().getName().replace(/.*CN=([^,]+).*/, "$1") + " | ważny do " + cert.getNotAfter());
  n++;
}
if (n == 0) print("  Brak klucza prywatnego w tym tokenie (np. certyfikat kwalifikowany nie został kupiony).");
try { prov.logout(); } catch (e) {}
