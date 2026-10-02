var cfg = arguments[0];
var p = new Packages.sun.security.pkcs11.SunPKCS11(cfg);
print("Provider loaded: " + p.getName());
try {
  var ks = java.security.KeyStore.getInstance("PKCS11", p);
  ks.load(null, null);
  var a = ks.aliases(); var n=0;
  while (a.hasMoreElements()) { var al=a.nextElement(); n++; var c=ks.getCertificate(al); print("  alias: "+al+(c? "  subject: "+c.getSubjectX500Principal():"")); }
  print("Entries: "+n);
} catch (e) { print("Keystore: " + e); }
