# Architektura: kto rozmawia z e-dowodem

[← README](README.md) · [Instalacja](INSTALL.md) · [Podpisywanie](RUN.md) · [Rodzaje podpisów](PODPISY.md) · **Architektura** · [Odnowione certyfikaty](UWAGA-ODNOWIONE-CERTYFIKATY.md)

![Kolejność: aplikacja e-dowód nawiązuje bezpieczne połączenie z kartą, a moduł PKCS#11 w Podpis GOV z niego korzysta](docs/kolejnosc-e-dowod-podpisgov.svg)

## Moduł PKCS#11 od PWPW nie jest klasycznym modułem

Typowy moduł PKCS#11, np. do karty kryptograficznej z certyfikatem kwalifikowanym, sam rozmawia z kartą.
Aplikacja ładuje go, a moduł otwiera czytnik, wybiera aplet na karcie i zwraca jej tokeny.

Moduł e-dowodu (`e-dowod-pkcs11-64.dylib`) działa inaczej:

1. **Sam nie nawiązuje bezpiecznego połączenia z kartą.** E-dowód wymaga szyfrowanego kanału PACE,
   zestawianego z numerem CAN (6 cyfr z przodu dowodu). Robi to **aplikacja e-dowód** od PWPW
   (menedżer w trayu), która pyta o CAN, zestawia kanał i odczytuje certyfikaty.
2. **Moduł korzysta z gotowej sesji.** Gdy aplikacja e-dowód zakończy odczyt, moduł pokazuje
   **5 wirtualnych slotów**, po jednym na każdą funkcję dowodu:

   **Tabela-źródło** (spina slot PKCS#11 ↔ etykietę CryptoTokenKit ↔ wystawcę certyfikatu ↔ funkcję/typ podpisu ↔ PIN;
   patrz też [PODPISY.md](PODPISY.md)). Łańcuch etykieta→wystawca→funkcja→PIN potwierdzony pomiarem
   (`tools/ctk-cert-map.swift`, `tools/ctk-sign-test.swift`, karta PWPW 4.3.4.28, 2026-10-08); indeks slotu z enumeracji
   modułu PKCS#11:

   | Slot | Token PKCS#11 | Etykieta CTK | Wystawca certyfikatu | Funkcja / typ podpisu (PODPISY.md) | PIN | PUK |
   |---|---|---|---|---|---|---|
   | 0 | E-Dowód (Authentication) | `eDO_pl-ID MSW` | `pl.ID Authentication CA` | **profil osobisty**: logowanie; potwierdzanie **podpisu zaufanego** (podpis składa serwer PZ) | **PIN1 — 4 cyfry** | PUK dowodu (8 cyfr) |
   | 1 | E-Dowód (Presence) | `eDO_pl-ID NFZ` | `pl.ID Presence CA` | **potwierdzenie obecności** (nie podpis) | brak | nie dotyczy |
   | 2 | E-Dowód (Authorization) | `eDO_pl-ID e-Podpis` | `pl.ID Authorization CA` | **podpis osobisty** | **PIN2 — 6 cyfr** | PUK dowodu (8 cyfr) |
   | 3 | E-Dowód (Qualified) | `CUZ Sigillum QCA …` | `CUZ Sigillum - QCA1`/`QCA2` | **podpis kwalifikowany** (opcjonalny, Sigillum) | **PIN kwalif. — 8 cyfr** | PUK dowodu (8 cyfr)¹ |
   | 4 | eMRTD | — (bez klucza, nie jest tożsamością CTK) | — | **dokument podróży** (ICAO, np. zdjęcie) | brak (dostęp przez CAN) | nie dotyczy |

   Etykiety CTK są **kosmetyczne i mylące** (PWPW): „MSW” = uwierzytelnienie, „NFZ” = obecność, „e-Podpis” = podpis
   osobisty — mapowanie wyżej usuwa dwuznaczność. Pełny odczyt daje **5 tożsamości**: Authentication, Presence,
   Authorization + **dwa** certyfikaty kwalifikowane po odnowieniu (stary `QCA1` + bieżący `QCA2`, oba z kluczem; CTK
   wiąże każdy z własnym kluczem — [UWAGA-ODNOWIONE-CERTYFIKATY.md](UWAGA-ODNOWIONE-CERTYFIKATY.md)). Przy **niepełnym**
   odczycie (słaby czytnik gubi cięższy applet kwalifikowany) kwalifikowany bywa widoczny jako **sam certyfikat bez
   klucza** → nie jest tożsamością → podpis kwalifikowany nie działa, mimo że certyfikat „jest”.

   ¹ Z doświadczenia autora: aktywacja certyfikatu kwalifikowanego w PWPW wymaga kodu PUK z koperty odebranej
   w urzędzie. **Niepotwierdzone:** czy na starszych dowodach trzeba było zaznaczyć tę opcję we wniosku (i czy bez
   tego potrzebny jest nowy dowód), oraz czy dotyczy to nowszych wersji e-dowodu. Potwierdzone jest tylko pole
   we wniosku dla **podpisu osobistego**.

   > **Podpis zaufany nie ma własnego slotu na dowodzie.** Składa go serwer Profilu Zaufanego, a potwierdzić go
   > można SMS-em, bankiem, mObywatelem **albo e-dowodem** (smartfon z NFC lub komputer z czytnikiem NFC),
   > czyli przez profil osobisty z PIN1. Porównanie wszystkich podpisów: [PODPISY.md](PODPISY.md).

3. **Bez tej sesji moduł widzi tylko czytnik.** Zwraca wtedy 1 slot i `CKR_TOKEN_NOT_PRESENT`, mimo że
   dowód leży na czytniku. Czytnik tylko krótko mrugnie (ok. 2 s, odczyt ATR) i nic więcej się nie dzieje.
   Podpis GOV pokazuje wówczas „Nie znaleziono certyfikatów” bez żadnej wskazówki.

4. **Jest klientem szyfrowanego „Core Cache”, nie rozmawia z kartą.** Napisy w `e-dowod-pkcs11-64.dylib`:
   `CACHE | ENC | SEND/RECV`, `Read file from Core Cache`, `Password found in cache`, `tries left PIN/PUK from cache`,
   `Password is empty and password type is not CAN or PUK`. Moduł **czyta stan karty (CAN, pliki, liczniki PIN) z cache**,
   który **zapełnia aplikacja e-Dowód po zestawieniu PACE** — nie z karty bezpośrednio. Potwierdzone testem izolacyjnym
   2026-10-08: podczas wywołań modułu **dioda czytnika nie zmienia stanu** (brak APDU), a w osobnym procesie moduł
   zwraca `CKR_TOKEN_NOT_PRESENT` nawet przy działającej aplikacji (nie uzyskał dostępu do cache).
   Pełny przebieg i komendy: **[test izolacyjny 2026-10-08](docs/test-izolacyjny-sesja-2026-10-08.md)**.

5. **Odbiega od standardu API.** Obok `C_GetFunctionList` moduł eksportuje **wendorową `C_SetCAN`** i ma własne kody
   `CKR_PACE_*` (spoza Cryptoki). Ale `C_SetCAN` wywołana z zewnątrz zwraca **`CKR_FUNCTION_NOT_SUPPORTED`** (test
   2026-10-08) — **nie jest** drogą podania CAN z zewnątrz; CAN pochodzi z cache. (Wcześniej błędnie ująłem `C_SetCAN`
   jako ścieżkę integracji — korekta na podstawie pomiaru.)

   > **Rodowód OpenSC / LGPL — otwarte.** [OpenSC#1992](https://github.com/OpenSC/OpenSC/issues/1992) (2020) dokumentuje,
   > że ówczesny moduł wywodził się z OpenSC (logi `[opensc-pkcs11]`, `cache-client.c`, `cache_get_can` — przodek
   > dzisiejszego „Core Cache”); PWPW odmówiło źródeł (tajemnica handlowa) → niezgodność z LGPL. Nasza binarka v4.3.4.28:
   > 0 symboli `sc_*`, 144 symbole C++ `PKCS11::` — spójne z przepisaniem, ale **nie wyklucza obfuskacji**. Nie zakładamy
   > ani nie wykluczamy; do domknięcia porównaniem z wersją archiwalną.
   >
   > **OpenSC ma własny sterownik e-dowodu — dowód projektowy, że proxy to wybór, nie wymóg karty.**
   > W źródłach OpenSC istnieje sterownik `edo` (`src/libopensc/card-edo.c`,
   > [PR #2023](https://github.com/OpenSC/OpenSC/pull/2023), 2020, autorstwa **Piotra Majkrzaka** — copyright
   > w nagłówku `card-edo.c`), nazwa „Polish eID card (e-dowód, eDO)",
   > ATR `3b:84:80:01:47:43:50:43:12`, oparty na kodzie niemieckiego dowodu (NPA). **Z projektu sam
   > zestawia PACEv2** z numerem CAN (`getenv("EDO_CAN")` lub config `card_driver edo { can = … }`),
   > czyta pliki PKCS#15 i podpisuje — bez aplikacji pośredniczącej. Profil karty to więc **PACEv2
   > (BSI TR-03110, rodzina NPA) + PKCS#15, a nie IAS-ECC**. Wniosek (projektowy): zależność modułu PWPW
   > od sesji aplikacji (Core Cache) jest **decyzją implementacyjną**, nie koniecznością narzuconą chipem.
   > **Build-flag:** sterownik `edo` jest za `#if defined(ENABLE_SM) && defined(ENABLE_OPENPACE)`;
   > **OpenSC 0.27.1 z Homebrew zbudowano bez OpenPACE**, więc go nie zawiera (brak na liście sterowników,
   > brak `EDO_CAN` w binariach). Zbudowaliśmy więc OpenSC ze źródeł z `--enable-sm --enable-openpace`
   > (sterownik `edo` obecny).
   >
   > **Wynik empiryczny (2026-10-09, żywa karta, ACR122U): OpenSC NIE odczytuje tego e-dowodu
   > end-to-end.** `edo` rozpoznaje ATR (`3b:84:80:01:47:43:50:43:12`), czyta CAN z `EDO_CAN`, startuje
   > PACE — ale **MSE:Set AT** (`00 22 C1 A4 … OID PACE … 83 01 02`) zwraca z karty **`69 86` „Command
   > not allowed (no current EF)"**, PACE pada (`edo_unlock: Error verifying CAN`), token „not recognized".
   > Powtarzalne, także po zatrzymaniu rozszerzenia CTK PWPW. **Przyczyna nierozstrzygnięta:** sterownik
   > `edo` (2020) vs obecny firmware karty / sekwencja PACE, ewentualnie APDU ACR122U. **NIE** „czytnik nie
   > umie PACE" — aplikacja PWPW zestawia PACE tym samym czytnikiem. Wniosek (ostrożny): otwarta ścieżka
   > **istnieje w kodzie (dowód projektowy, że proxy = wybór), ale nie domyka się end-to-end wobec obecnej
   > karty — wymaga łatki sterownika lub czytnika klasy PACE.** (Znany limit OpenSC: długie APDU — ten sam
   > objaw, co słaby czytnik gubiący cięższy applet.)

### CryptoTokenKit a PKCS#11: dwa frontendy, jedna sesja PWPW

To nie są dwa warianty tego samego. **PKCS#11** (Cryptoki) to **standardowe, wieloplatformowe API w C**: aplikacja
ładuje moduł (`.dylib`/`.so`/`.dll`) do swojego procesu i woła `C_Login`/`C_Sign`; używają go NSS/Firefox, Java
(SunPKCS11), wiele programów. **CryptoTokenKit** to **natywny framework Apple (macOS/iOS)**: rozszerzenie-token
publikuje tożsamości karty do systemowego **Pęku kluczy**, a aplikacje używają `Security.framework`/`SecKey` — bez
ładowania modułu per aplikacja, z systemowym oknem PIN. W obrębie macOS CTK jest **nowszą generacją** (wprowadzony
ok. macOS 10.10–10.12, następca `tokend`/CDSA) — ale nie jest uniwersalnym następcą PKCS#11, który pozostaje
standardem międzyplatformowym. Dla e-dowodu **oba są tylko różnymi frontendami nad sesją zestawioną przez aplikację
e-dowód PWPW** — żaden nie omija aplikacji. Różnią się sposobem współdzielenia (test izolacyjny 2026-10-08):
- **CTK:** aplikacja **publikuje token+tożsamości do systemowego `ctkd`**; są widoczne międzyprocesowo i **persystują
  po zamknięciu aplikacji**. To ścieżka PodpisGOV-ng — i dlatego działa.
- **PKCS#11:** moduł jest **klientem szyfrowanego Core Cache** zapełnianego przez aplikację; w obcym procesie **nie
  uzyskał sesji** w żadnym stanie (S1–S3).

PodpisGOV-ng wybiera CTK dla czystszej integracji (Pęk kluczy, systemowy PIN, odporność na duplikat `CKA_ID` przy
odnowionym certyfikacie) — nie po to, by uniezależnić się od aplikacji PWPW (nie da się: sesję i tak zestawia ona).

### Dlaczego integracja spoza PWPW jest trudna (casus KIR / Szafir / ZUS)

Konsekwencja powyższego dla dostawcy, który nie jest PWPW (np. KIR w ePłatniku ZUS): karta jest osiągalna **tylko przez
proprietarny, szyfrowany Core Cache, który zapełnia wyłącznie aplikacja PWPW** (po PACE). Generyczny host PKCS#11
(Szafir SDK) robi standardową ścieżkę „listuj sloty → `C_Login(PIN)` → `C_Sign`”, ale cache jest pusty, więc dostaje
`CKR_TOKEN_NOT_PRESENT` — dokładnie objaw z ZUS („Brak certyfikatów… wskaż sterownik karty”). **Nawet my**, ładując
oryginalny moduł PWPW w standardowym JVM, nie uzyskaliśmy sesji z zewnątrz (test 2026-10-08), a `C_SetCAN` z zewnątrz =
`NOT_SUPPORTED`. Część niestandardowości jest **technicznie uzasadniona** (PACE/CAN chroni karty bezstykowe i standard
PKCS#11 go nie definiuje) — z analizy **nie wynika zamiar** blokowania konkurencji, a jedynie fakt, że ta warstwa
**podnosi koszt integracji każdemu spoza PWPW**. Przy producencie karty (PWPW) będącym konkurentem KIR w usługach
zaufania to strukturalna przewaga PWPW. Wątek ZUS prowadzony osobno, od strony prawnej.

### Generacje e-dowodu i chipy (z modułu PWPW 4.3.4.28)

Moduł PWPW obsługuje wiele wariantów karty — ujawniają to klasy w binarce `e-dowod-pkcs11-64.dylib`:

| Warstwa | Warianty widoczne w module |
|---|---|
| Chip / aplet | NXP P60 ChipDoc 2.0, NXP P71 ChipDoc 3.0, NXP P71 SmartApp ID 5.0, Thales MAV 5.0 |
| Kontroler dokumentu (generacja) | e-dowód 1.0, 2.0, 2.1, 2.2 |
| Protokoły | PACE, Chip Authentication, Mutual Authentication |

Karta testowa w tym repo: ATR `3b:84:80:01:47:43:50:43:12`, aplet podpisowy o etykiecie **„ChipDoc"**
(AID `A0 00 00 01 67` + „ESIGN"), kanał **PACE ECDH-GM-AES-256-CBC-CMAC na brainpoolP384r1**.

**Co to znaczy dla podpisów ([PODPISY.md](PODPISY.md)):** funkcje karty (5 slotów — uwierzytelnienie/PIN1,
obecność, podpis osobisty/PIN2, podpis kwalifikowany/PIN-8, eMRTD) są **ortogonalne** do generacji sprzętu.
Generacja/chip wpływa na parametry kryptograficzne (np. krzywa i siła PACE), nie na to, które podpisy dowód
udostępnia. **Nie mapujemy** generacji na zakres funkcji — moduł rozróżnia warianty, ale z samej binarki nie
wynika „generacja X = funkcja Y".

**Czego to NIE wyjaśnia:** awarii PACE w OpenSC (`69 86`). Sterownik `edo` celuje w **ten sam ATR** co nasza
karta, więc „inna generacja" nie jest wyjaśnieniem; przyczyna `69 86` pozostaje nieustalona
([docs/opensc-edo-pace-RE-2026-10-09.md](docs/opensc-edo-pace-RE-2026-10-09.md)).

### Kody PIN i PUK: skąd je mieć

Według [gov.pl — Uzyskaj dowód osobisty](https://www.gov.pl/web/gov/uzyskaj-dowod-osobisty):

- **PIN1 (4 cyfry, logowanie)** i **PIN2 (6 cyfr, podpis osobisty)** ustalasz w urzędzie przy odbiorze dowodu.
  PIN2 tylko wtedy, gdy we wniosku zaznaczono podpis osobisty. Możesz to też zrobić **później, w dowolnym urzędzie gminy**.
- **PUK (8 cyfr)** dostajesz w kopercie razem z dowodem. Służy do odblokowania PIN-ów po 3 błędnych próbach i do ich zmiany.
  Możesz go nie odebrać od razu: **czeka w urzędzie, który wydał dowód**.
- Gdy dowód odbiera **pełnomocnik**, i tak musisz **osobiście** przyjść do urzędu, żeby ustalić PIN-y lub odebrać PUK.
- Więcej o zmianie PIN-ów i o PUK: [gov.pl/web/e-dowod](https://www.gov.pl/web/e-dowod).

### Tunel PACE i numer CAN

Szyfrowany kanał z kartą (**tunel PACE**) zestawia aplikacja e-dowód, a każda nowa sesja wymaga numeru CAN:
wpisanego ręcznie albo zapamiętanego w aplikacji (opcja „zapamiętaj CAN”). Z praktyki: gdy sesja działa
niestabilnie, pomaga wyłączenie i ponowne włączenie tej opcji.

> [!WARNING]
> **Odnowiony certyfikat kwalifikowany:** na karcie zostają dwa certyfikaty na ten sam klucz, a podpis kwalifikowany
> przez Podpis GOV kończy się błędem. Wyjaśnienie krok po kroku z analogią:
> **[UWAGA-ODNOWIONE-CERTYFIKATY.md](UWAGA-ODNOWIONE-CERTYFIKATY.md)**.

### Kto korzysta z sesji

| Program | Dostawca | Jak sięga do karty | Wynik na Apple Silicon |
|---|---|---|---|
| **e-dowód Podpis elektroniczny** (eDOSign) | PWPW | moduł PKCS#11 przez własny wrapper IAIK z własną biblioteką natywną | ✅ widzi certyfikaty, podpisuje (podpis osobisty, kwalifikowany) |
| **Podpis GOV** (przez PodpisGOV-x64) | COI | moduł PKCS#11: lista certyfikatów przez API IAIK, podpis przez SunPKCS11 | ✅ **podpis osobisty złożony na podpis.gov.pl**; widzi też certyfikat kwalifikowany (2026-10-02) |
| **Przeglądarka** (Firefox, Safari, Chrome): logowanie na login.gov.pl | Apple / PWPW | rozszerzenie CryptoTokenKit (Firefox: wbudowane `osclientcerts`) | ✅ **logowanie do e-Doręczeń e-dowodem, PIN1** (2026-10-02). Przeglądarka działa natywnie, ale rozszerzenie CryptoTokenKit PWPW jest tylko x86_64 i działa przez Rosettę. |

**Wynik analizy (2026-10-02).** Moduł PWPW zwraca poprawne certyfikaty każdą drogą: bezpośrednio, przez
wrapper Javy 8 i Javy 21 oraz przez kod Podpis GOV (`PKCS11TokenUtils.getPKCS11Token`), także ze ścieżką
zawierającą „ó”. Pojedynczy błąd „Wystąpił błąd ładowania biblioteki: null” wystąpił, gdy kilka komponentów
naraz korzystało z karty. Podpis GOV nie sprawdza wtedy, czy odczytany certyfikat nie jest pusty
(`getByteArrayValue()` → `null` → `NullPointerException`). Narzędzia: `tools/p11proxy/` (logujący moduł
pośredniczący PKCS#11) i `tools/P11Values.java`.

Do tej samej karty sięga też **rozszerzenie CryptoTokenKit** od PWPW (`pl.pwpw.e-dowod.ctkapp.ext`, dostarczane w pakiecie aplikacji **e-dowód**, nie „e-dowód Podpis elektroniczny”), czyli systemowy dostęp macOS dla
Safari, Pęku kluczy i Chrome. Trzy komponenty jednego dostawcy korzystają z jednej karty i jednego wolnego
łącza NFC, więc kolejność ma znaczenie.

## Właściwa kolejność

1. **Aplikacja e-dowód:** połóż dowód, wpisz CAN i poczekaj na komunikat o odczytanych certyfikatach.
   Na wolnym czytniku (np. ACR122U) trwa to 20–40 sekund, a czytnik w tym czasie daje sygnał i mruga.
2. **Podpis GOV** (przez `PodpisGOV-x64.app`). Okno z opcją „Dodaj wystawcę” otworzysz, klikając
   `PodpisGOV-x64` ponownie, gdy aplikacja już działa.
3. **Strona gov.pl** łączy się z Podpis GOV przez `https://localhost:8640` i prosi o podpis.

### E-dowód na Macu: trzy drogi (podpis pliku i logowanie)

| | Program | Gdzie | Uwagi |
|---|---|---|---|
| **A** | **e-dowód Podpis elektroniczny** (PWPW) | lokalnie, bez przeglądarki | podpis osobisty lub kwalifikowany; działa bez tego obejścia. Nie ma łącza z WWW: żadna aplikacja PWPW nie nasłuchuje na porcie sieciowym (sprawdzone 2026-10-02) |
| **B** | **[podpis.gov.pl](https://podpis.gov.pl)** + Podpis GOV (COI) | w przeglądarce | wgrywasz plik, strona woła Podpis GOV; na Apple Silicon przez to obejście |
| **C** | **logowanie** na login.gov.pl (np. e-Doręczenia): E-dowód → czytnik NFC | przeglądarka | uwierzytelnienie TLS certyfikatem klienta (profil osobisty, PIN1) przez CryptoTokenKit; działa natywnie, bez obejścia i **bez Podpis GOV** (sprawdzone przy zamkniętym Podpis GOV, 2026-10-02) |

**Dwa łączniki karty z WWW.** Droga A (strzałka z sesji do „e-dowód Podpis elektroniczny”) działa wyłącznie lokalnie. Z przeglądarką kartę łączą tylko: **B** — Podpis GOV (COI) przez lokalne API na portach 8640/8641, wyłącznie do **podpisu**; **C** — rozszerzenie CryptoTokenKit (PWPW) przez macOS, do **uwierzytelnienia** (TLS z certyfikatem klienta na login.e-dowod.gov.pl). Logowanie e-dowodem nie korzysta więc z Podpis GOV.

### Topologia logowania: SAML (Węzeł) + X.509 (karta)

Logowanie e-dowodem to kompletny, standardowy stos federacyjny — nie „tylko certyfikat klienta”.
Potwierdzone przechwytem HAR (`captures/edor-edor-content-pz-edowod.har`, logowanie do e-Doręczeń,
2026-10-03). Kolejność ogniw:

1. Usługa końcowa (np. e-Doręczenia) → **`login.gov.pl` = Krajowy Węzeł Identyfikacji** — hub SAML
   (`POST /login/SingleSignOnService`).
2. Węzeł przekazuje uwierzytelnienie do **e-dowodu jako osobnego IdP SAML**: `login.e-dowod.gov.pl`
   ma **własny** `/sie/SingleSignOnService` (SIE = System Identyfikacji Elektronicznej) → 302 do swojej SPA.
3. SPA (`sie-frontend`, Angular) zbiera wybór narzędzia (czytnik NFC) i CAN.
4. **Dowód posiadania klucza to X.509**: `POST /sie/login/certLogin` wymusza certyfikat klienta przez
   **renegocjację TLS 1.2** — podpisuje klucz *Authentication* (slot 0, PIN1).
5. IdP e-dowodu wystawia asercję SAML do Węzła, Węzeł — asercję do usługi.

Czyli **SAML** jest w dwóch ogniwach (usługa↔Węzeł oraz Węzeł↔IdP-e-dowód), a **X.509/TLS client-cert**
w jednym, precyzyjnym punkcie (`certLogin` na `login.e-dowod.gov.pl`). Protokoły są pełne i poprawne —
to nie w nich leży problem interoperacyjności.

**Logowanie (C) w praktyce:** po „Zaloguj się” macOS pokazuje ogólne okno *„Firefox próbuje podpisać dane”*
(albo podobne dla Safari/Chrome). To podpis kluczem z dowodu wymagany do połączenia z certyfikatem klienta.
**Przy logowaniu to zawsze PIN1 (4 cyfry).** **Firefox pyta o PIN dwa razy, Safari raz** (sprawdzone 2026-10-03
w logach systemowych CryptoTokenKit, logowanie do e-Doręczeń):
- **Safari:** okno wyboru certyfikatu („Witryna login.e-dowod.gov.pl wymaga certyfikatu klienta”), potem jedno
  sprawdzenie PIN-u i **jedna** operacja podpisu na karcie.
- **Firefox:** **dwie** operacje podpisu w odstępie ok. 1 s, czyli dwa połączenia TLS z certyfikatem klienta.
  Przed każdą rozszerzenie PWPW na nowo sprawdza dostęp (`evaluateAccessControl`), stąd drugi PIN.

**Dlaczego Firefox podpisuje dwa razy** (2026-10-03: przechwyt TCP `tcpdump`, log sieciowy Firefoksa, logi
CryptoTokenKit). `login.e-dowod.gov.pl` działa tylko w TLS 1.2 i prosi o certyfikat klienta dopiero przez
**renegocjację** przy `POST /sie/login/certLogin`.
- **Safari** otwiera osobne połączenie na każde żądanie. POST jest pierwszym żądaniem na świeżym połączeniu → serwer
  wysyła `CertificateRequest` i **czeka** (w teście 13 s na PIN) → jeden podpis chipem, logowanie.
- **Firefox** wysyła POST tym samym połączeniem co wcześniejsze żądania (keep-alive) → `CertificateRequest` →
  **po ok. 0,9 s serwer zamyka połączenie (FIN)**, gdy użytkownik wciąż wpisuje PIN → chip kończy podpis nr 1, ale
  połączenie już nie istnieje, więc **podpis nie zostaje wysłany** → Firefox ponawia POST na nowym połączeniu → podpis nr 2.

Przyczyna leży po stronie serwera: przerywa renegocjację na połączeniu, które obsłużyło już wcześniejsze żądania (wygląda
to na krótki limit bezczynności keep-alive w trakcie renegocjacji). Firefox używa połączeń ponownie, więc trafia na ten
błąd. Mógłby też przerwać prośbę do chipu, gdy połączenie zostanie zamknięte w trakcie czekania na PIN. Pierwszy podpis
nigdy nie opuszcza komputera. Rozszerzenie PWPW nie zachowuje uwierzytelnienia między operacjami, dlatego każdy podpis
to osobny PIN. Obejście: Safari loguje z jednym PIN-em.

**podpis.gov.pl to nie tylko podpisywarka plików, ale też router podpisu.** Przyjmuje pliki wgrane przez
użytkownika oraz pliki przekazane do podpisu przez inne e-usługi, a następnie kieruje podpis do wybranego kanału:

| Kanał | Gdzie działa | Rodzaj podpisu |
|---|---|---|
| **Podpis GOV** (COI) | aplikacja na komputerze, lokalne API `localhost:8640` | osobisty lub kwalifikowany z e-dowodu (droga B) |
| **e-dowód w telefonie** (aplikacja eDO App) | smartfon z NFC, powiązany ze stroną kodem QR | podpis z e-dowodu przez telefon |
| **Profil Zaufany** | przeglądarka, potwierdzenie kodem SMS | podpis zaufany |
| **mObywatel** | aplikacja mobilna | m.in. kwalifikowany online, w tym pula darmowych podpisów (wg informacji użytkownika: 5) |

Na Macu z Apple Silicon problem dotyczy tylko pierwszego kanału (Podpis GOV), bo tylko on ładuje x86_64-owy
moduł PKCS#11 na komputerze. Pozostałe kanały działają poza komputerem lub bez czytnika.
Na diagramie skrót „podpisywarka i router”.

Inne e-usługi gov.pl (formularze, wnioski) wywołują Podpis GOV tak samo jak B, przez lokalne API
(`/rest/certificates`, `/rest/sign`), ale to usługa decyduje, co i kiedy jest podpisywane.

## Gdzie działa nasze obejście

Obejście z tego repozytorium dotyczy wyłącznie kroku 2. Oprócz uruchamiania Podpis GOV na Javie x64 launcher
utrzymuje w `~/.pksigner/config.ini` ścieżkę do modułu bez „ó”. Podpis GOV ładuje moduł **dwiema drogami**:
listę certyfikatów przez API IAIK (radzi sobie z „ó”) i **sam podpis przez SunPKCS11** (nie radzi sobie). Podpis GOV ma wbudowaną Javę dla Apple Silicon
(arm64), a moduł PWPW istnieje tylko dla procesorów Intel (x86_64). Skrypt uruchamia więc Podpis GOV
na Javie x64 z JavaFX (Azul Zulu 8) przez Rosettę 2. Kroki 1 i 3 działają bez zmian.

Szczegóły techniczne: [README — Przyczyna](README.md#przyczyna).

## Jak to sprawdzono

- Długości PIN-ów i flagi tokenów odczytano z karty **bez wpisywania PIN-u** (`ulMinPinLen` / `ulMaxPinLen`):
  `zsh tools/test-podpisow.sh` (krok 1).
- Brak tokenów przed zakończeniem odczytu w aplikacji e-dowód i 5 tokenów po nim:
  `zsh patch-podpisgov-x64.sh --check`.
- Zatrzymanie samego rozszerzenia CryptoTokenKit nie pomaga. Moduł potrzebuje sesji aplikacji e-dowód.
- **Podpis kwalifikowany odnowionym certyfikatem działa przez CryptoTokenKit** (2026-10-03, bez Podpis GOV; program
  podpisujący arm64, ale rozszerzenie CTK PWPW `e-dowod_ctkext` jest tylko x86_64 i działa przez Rosettę, więc ta droga
  też przestanie działać po końcu Rosetty, jeśli PWPW nie wyda wersji arm64): rozszerzenie z aplikacji e-dowód udostępnia każdy certyfikat kwalifikowany jako osobną tożsamość
  (certyfikat + klucz), więc duplikat `CKA_ID` nie przeszkadza. Test: `tools/ctk-sign-test.swift` (RSA 2048,
  PKCS#1 v1.5 SHA-256, podpis zweryfikowany certyfikatem). To podstawa ewentualnego lekkiego zamiennika Podpis GOV:
  e-usługi wysyłają do `/rest/sign` tylko dane do podpisu (`toBeSigned`, np. `SignedInfo` XAdES z ePUAP) i algorytm
  skrótu, a plik podpisu składa serwer.

Ikony aplikacji na diagramie należą do PWPW S.A. (e-dowód) i COI (Podpis GOV). Użyto ich wyłącznie do
identyfikacji aplikacji.
