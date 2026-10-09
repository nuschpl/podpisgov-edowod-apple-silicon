import Foundation
import Security
func issuerCN(_ c:SecCertificate)->String {
  guard let vals=SecCertificateCopyValues(c,[kSecOIDX509V1IssuerName] as CFArray,nil) as? [CFString:Any],
        let d=vals[kSecOIDX509V1IssuerName] as? [CFString:Any], let a=d[kSecPropertyKeyValue] as? [[CFString:Any]] else {return "?"}
  for kv in a { if (kv[kSecPropertyKeyLabel] as? String)=="2.5.4.3" { return (kv[kSecPropertyKeyValue] as? String) ?? "?" } }
  return "?"
}
func serial(_ c:SecCertificate)->String { (SecCertificateCopySerialNumberData(c,nil) as Data?)?.map{String(format:"%02x",$0)}.joined() ?? "?" }

print("===== TOŻSAMOŚCI (cert + KLUCZ → można podpisać) =====")
let iq:[String:Any]=[kSecClass as String:kSecClassIdentity, kSecAttrAccessGroup as String:kSecAttrAccessGroupToken,
  kSecMatchLimit as String:kSecMatchLimitAll, kSecReturnRef as String:true, kSecReturnAttributes as String:true]
var io:CFTypeRef?
let r1=SecItemCopyMatching(iq as CFDictionary,&io)
var idSerials=Set<String>()
if r1==errSecSuccess, let a=io as? [[String:Any]] {
  for d in a {
    let label=(d[kSecAttrLabel as String] as? String) ?? "(brak)"
    let idn = d[kSecValueRef as String] as! SecIdentity
    var c:SecCertificate?; SecIdentityCopyCertificate(idn,&c)
    guard let cert=c else {continue}
    let s=serial(cert); idSerials.insert(s)
    print("  '\(label)'  ⟵ wystawca: \(issuerCN(cert))  | serial \(s)")
  }
} else { print("  (rc=\(r1), brak — karta na czytniku?)") }

print("\n===== WSZYSTKIE CERTYFIKATY (także bez klucza) =====")
let cq:[String:Any]=[kSecClass as String:kSecClassCertificate, kSecAttrAccessGroup as String:kSecAttrAccessGroupToken,
  kSecMatchLimit as String:kSecMatchLimitAll, kSecReturnRef as String:true]
var co:CFTypeRef?
let r2=SecItemCopyMatching(cq as CFDictionary,&co)
if r2==errSecSuccess, let a=co as? [SecCertificate] {
  for cert in a {
    let s=serial(cert); let hasKey=idSerials.contains(s)
    var cn:CFString?; SecCertificateCopyCommonName(cert,&cn)
    print("  wystawca: \(issuerCN(cert))  | CN \(cn as String? ?? "?") | serial \(s) | KLUCZ: \(hasKey ? "TAK ✅":"NIE ❌")")
  }
} else { print("  (rc=\(r2))") }
