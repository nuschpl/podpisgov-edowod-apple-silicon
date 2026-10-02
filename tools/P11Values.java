import java.lang.reflect.Field;
import sun.security.pkcs11.wrapper.*;

/**
 * Odczyt CKA_VALUE / CKA_ID certyfikatów przez natywny wrapper PKCS#11 JDK (libj2pkcs11),
 * tę samą warstwę, której używa Podpis GOV. Bez logowania, bez PIN-u.
 *
 * Kompilacja (dowolny JDK 21):
 *   javac --add-modules jdk.crypto.cryptoki --add-exports jdk.crypto.cryptoki/sun.security.pkcs11.wrapper=ALL-UNNAMED -d out tools/P11Values.java
 * Uruchomienie (Java x64 przez Rosettę):
 *   arch -x86_64 <java21-x64> --add-exports jdk.crypto.cryptoki/sun.security.pkcs11.wrapper=ALL-UNNAMED -cp out P11Values <modul.dylib>
 */
public class P11Values {
    public static void main(String[] a) throws Exception {
        CK_C_INITIALIZE_ARGS init = new CK_C_INITIALIZE_ARGS();
        init.flags = PKCS11Constants.CKF_OS_LOCKING_OK;
        PKCS11 p = PKCS11.getInstance(a[0], "C_GetFunctionList", init, false);
        System.out.println("Java " + System.getProperty("java.version") + " (" + System.getProperty("os.arch") + ")");
        StringBuilder sb = new StringBuilder();
        for (long s : p.C_GetSlotList(true)) {
            long h = p.C_OpenSession(s, PKCS11Constants.CKF_SERIAL_SESSION, null, null);
            p.C_FindObjectsInit(h, new CK_ATTRIBUTE[]{ new CK_ATTRIBUTE(PKCS11Constants.CKA_CLASS, PKCS11Constants.CKO_CERTIFICATE) });
            long[] objs = p.C_FindObjects(h, 20);
            p.C_FindObjectsFinal(h);
            for (long o : objs) {
                CK_ATTRIBUTE[] t = { new CK_ATTRIBUTE(PKCS11Constants.CKA_VALUE), new CK_ATTRIBUTE(PKCS11Constants.CKA_ID) };
                try {
                    p.C_GetAttributeValue(h, o, t);
                    sb.append(s).append(":VALUE=").append(len(t[0].pValue)).append("/ID=").append(len(t[1].pValue)).append("  ");
                } catch (PKCS11Exception e) {
                    sb.append(s).append(":").append(e.getMessage()).append("  ");
                }
            }
            p.C_CloseSession(h);
        }
        System.out.println("certyfikaty: " + sb);
    }

    static String len(Object v) {
        if (v == null) return "null";
        if (v instanceof byte[]) return ((byte[]) v).length + "B";
        if (v instanceof char[]) return ((char[]) v).length + "z";
        return v.getClass().getSimpleName();
    }
}
