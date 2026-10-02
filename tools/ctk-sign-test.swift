// Test: podpis przez CryptoTokenKit (rozszerzenie PWPW z aplikacji e-dowód), natywnie arm64, bez Podpis GOV.
// Szuka tożsamości (certyfikat + klucz na karcie) po fragmencie etykiety, podpisuje próbne dane i weryfikuje
// podpis kluczem publicznym z certyfikatu. PIN pobiera macOS; program go nie widzi.
//
// Budowa i uruchomienie:
//   swiftc -O tools/ctk-sign-test.swift -o /tmp/ctk-sign-test
//   /tmp/ctk-sign-test "QCA 2026-08-19"      # bez argumentu: lista tożsamości z karty
import Foundation
import Security

func identities() -> [(label: String, identity: SecIdentity)] {
    let q: [String: Any] = [
        kSecClass as String: kSecClassIdentity,
        kSecAttrAccessGroup as String: kSecAttrAccessGroupToken,
        kSecMatchLimit as String: kSecMatchLimitAll,
        kSecReturnRef as String: true,
        kSecReturnAttributes as String: true,
    ]
    var out: CFTypeRef?
    guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let items = out as? [[String: Any]] else { return [] }
    return items.compactMap { item in
        guard let ref = item[kSecValueRef as String] else { return nil }
        let label = item[kSecAttrLabel as String] as? String ?? "?"
        return (label, ref as! SecIdentity)
    }
}

func describe(_ cert: SecCertificate) -> String {
    let summary = SecCertificateCopySubjectSummary(cert) as String? ?? "?"
    var err: Unmanaged<CFError>?
    let serial = (SecCertificateCopySerialNumberData(cert, &err) as Data?)?.map { String(format: "%02x", $0) }.joined() ?? "?"
    var notAfter = "?"
    if let vals = SecCertificateCopyValues(cert, [kSecOIDX509V1ValidityNotAfter] as CFArray, nil) as? [String: Any],
       let d = vals[kSecOIDX509V1ValidityNotAfter as String] as? [String: Any], let n = d[kSecPropertyKeyValue as String] as? NSNumber {
        notAfter = ISO8601DateFormatter().string(from: Date(timeIntervalSinceReferenceDate: n.doubleValue))
    }
    return "\(summary) · nr seryjny \(serial) · ważny do \(notAfter)"
}

let ids = identities()
if ids.isEmpty { print("Brak tożsamości z karty. Czy aplikacja e-dowód odczytała certyfikaty?"); exit(1) }
guard CommandLine.arguments.count > 1 else {
    for i in ids { var c: SecCertificate?; SecIdentityCopyCertificate(i.identity, &c); print("• \(i.label)\n    \(c.map(describe) ?? "?")") }
    exit(0)
}
let needle = CommandLine.arguments[1]
let matches = ids.filter { $0.label.contains(needle) }
guard matches.count == 1, let chosen = matches.first else {
    print("Etykieta „\(needle)” pasuje do \(matches.count) tożsamości; potrzebna dokładnie jedna."); exit(1)
}
var certOut: SecCertificate?, keyOut: SecKey?
SecIdentityCopyCertificate(chosen.identity, &certOut)
SecIdentityCopyPrivateKey(chosen.identity, &keyOut)
guard let cert = certOut, let key = keyOut, let pub = SecCertificateCopyKey(cert) else { print("Brak certyfikatu lub klucza."); exit(1) }

let attrs = SecKeyCopyAttributes(pub) as? [String: Any] ?? [:]
let isEC = (attrs[kSecAttrKeyType as String] as? String) == (kSecAttrKeyTypeECSECPrimeRandom as String)
let bits = attrs[kSecAttrKeySizeInBits as String] as? Int ?? 0
let alg: SecKeyAlgorithm = isEC ? .ecdsaSignatureMessageX962SHA256 : .rsaSignatureMessagePKCS1v15SHA256
print("Tożsamość: \(chosen.label)\n  \(describe(cert))\n  klucz: \(isEC ? "EC" : "RSA") \(bits) bit, algorytm \(alg.rawValue)")
guard SecKeyIsAlgorithmSupported(key, .sign, alg) else { print("Karta nie obsługuje tego algorytmu."); exit(1) }

let data = "Test podpisu przez CryptoTokenKit \(ISO8601DateFormatter().string(from: Date()))".data(using: .utf8)!
print("Podpisuję próbne dane (\(data.count) B). macOS poprosi o PIN certyfikatu…")
var err: Unmanaged<CFError>?
guard let sig = SecKeyCreateSignature(key, alg, data as CFData, &err) as Data? else {
    print("❌ Podpis nieudany: \(err!.takeRetainedValue())"); exit(2)
}
let ok = SecKeyVerifySignature(pub, alg, data as CFData, sig as CFData, &err)
print(ok ? "✅ Podpis (\(sig.count) B) zweryfikowany kluczem publicznym z wybranego certyfikatu." : "❌ Weryfikacja nieudana: podpis nie pasuje do certyfikatu.")
exit(ok ? 0 : 3)
