# Specyfikacje referencyjne (źródła)

Pliki PDF w tym katalogu są **gitignorowane** (duże binaria / warunki redystrybucji) — tutaj trzymamy **źródła**,
żeby dało się je odtworzyć.

## BSI TR-03110 Part 3 v2.2 — PACE / EAC (Advanced Security Mechanisms for MRTDs)

- **Plik lokalny:** `BSI_TR-03110_Part-3-V2.2.pdf` (gitignored)
- **Źródło:** https://www.bsi.bund.de/SharedDocs/Downloads/EN/BSI/Publications/TechGuidelines/TR03110/BSI_TR-03110_Part-3-V2_2.pdf?__blob=publicationFile&v=1
- **Pobrano:** 2026-10-09
- **Rozmiar / typ:** 1.5 MB, PDF 1.6
- **sha256:** `168d6d55619d60fd65e58520a4547cf7366ede0e0f42973dcf0b590a7eb2fab0`

**Do czego:** kanoniczna specyfikacja **PACE** (Password Authenticated Connection Establishment) i Chip Authentication —
struktura `MSE:Set AT`, `GENERAL AUTHENTICATE` (Generic Mapping), OID protokołów, parametry domeny. Potrzebna do łatki
sterownika OpenSC `edo` pod e-dowód (wątek: `../opensc-edo-pace-RE-2026-10-09.md`, [OpenSC#1831](https://github.com/OpenSC/OpenSC/issues/1831)).

**Odtworzenie (gdy brak pliku):**
```bash
curl -L -o docs/specs/BSI_TR-03110_Part-3-V2.2.pdf \
  'https://www.bsi.bund.de/SharedDocs/Downloads/EN/BSI/Publications/TechGuidelines/TR03110/BSI_TR-03110_Part-3-V2_2.pdf?__blob=publicationFile&v=1'
# weryfikacja: shasum -a 256 powinno dać hash jak wyżej (BSI może wydać nowszy revision — wtedy hash się zmieni)
```
