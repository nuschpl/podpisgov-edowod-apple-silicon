# Podpis GOV + e-dowód na Macach z Apple Silicon

> **KISS** — *Keep It Simple, Standard*. Apeluję do PWPW i COI: niech e-dowód
> i Podpis GOV po prostu działają razem na każdym współczesnym Macu.

Skrypt, dzięki któremu **Podpis GOV** (COI) zaczyna widzieć certyfikaty z **e-dowodu**
(moduł PKCS#11 od PWPW) na Macach z procesorami Apple Silicon (M1, M2, M3, M4…).

> [!WARNING]
> **To obejście ma termin ważności: działa najdłużej do macOS 27.**
> Działa wyłącznie dzięki **Rosetcie 2**, czyli tłumaczowi kodu Intel (x86_64) wbudowanemu
> w macOS. Apple oficjalnie ogłosiło, że **macOS 27 (wydany we wrześniu 2026) jest ostatnią
> wersją obsługującą Rosettę** i że po nim aplikacje tylko dla Intela przestaną działać na Macach
> z Apple Silicon. Zostanie jedynie wsparcie dla starszych, nierozwijanych gier
> ([Apple Developer, 1 września 2026](https://developer.apple.com/news/?id=w5ngl9k2);
> [Apple Support: aplikacje Intel na Macach z Apple Silicon](https://support.apple.com/en-us/102527)).
> Od macOS 26.4 system może już wyświetlać ostrzeżenia przy uruchamianiu takich aplikacji.
>
> Jeśli PWPW nie wyda modułu PKCS#11 w wersji **arm64 (Apple Silicon)** przed kolejną wersją
> macOS, e-dowód **przestanie działać na Macach** — w Podpis GOV, w aplikacjach PWPW i w każdym
> innym programie korzystającym z PKCS#11.

> [!NOTE]
> **COI może pomóc tylko częściowo.** Podpis GOV mógłby np. dołączać Javę x64 albo uruchamiać
> się przez Rosettę, gdy wskazana biblioteka jest dla Intela, lub przynajmniej wyświetlać czytelny
> błąd zamiast pustej listy. Byłoby to jednak tylko to samo obejście w wersji oficjalnej, z tą
> samą datą ważności. **Trwałe rozwiązanie leży wyłącznie po stronie PWPW**, które jest
> właścicielem jedynego oficjalnego modułu PKCS#11 do e-dowodu.

## Problem

W Podpis GOV wybierasz *Dodaj wystawcę z dysku* i wskazujesz bibliotekę e-dowodu:

```
/Applications/e-dowód.app/Contents/lib/e-dowod-pkcs11-64.dylib
```

Aplikacja nie zgłasza żadnego błędu, ale pokazuje tylko **„Nie znaleziono certyfikatów”**
i **„Brak zdefiniowanych bibliotek”**.

## Przyczyna

| Komponent | Właściciel | Architektura |
|---|---|---|
| `e-dowód.app` — oprogramowanie pośredniczące i moduł PKCS#11 `e-dowod-pkcs11-64.dylib` | **PWPW S.A.** (Polska Wytwórnia Papierów Wartościowych) | tylko **x86_64** (Intel) |
| `e-dowód Podpis elektroniczny.app` | **PWPW S.A.** | tylko x86_64 |
| `PodpisGOV.app` | **COI** (Centralny Ośrodek Informatyki) dla KPRM | dołączona Java 8 to **arm64** |

1. **Niezgodne architektury.** Podpis GOV wczytuje moduł PKCS#11 do własnego procesu (Java
   SunPKCS11). Java dołączona do aplikacji działa natywnie na arm64, a moduł PWPW istnieje tylko
   w wersji dla procesorów Intel. macOS nie pozwala załadować biblioteki x86_64 do procesu arm64:

   ```
   dlopen(.../e-dowod-pkcs11-64.dylib): mach-o file, but is an incompatible architecture
   (have 'x86_64', need 'arm64e' or 'arm64')
   ```

2. **Polski znak w ścieżce.** Parser konfiguracji SunPKCS11 w Javie 8 odrzuca litery spoza
   ASCII, a moduł leży w `/Applications/e-dowód.app` (litera „ó”):

   ```
   sun.security.pkcs11.ConfigurationException: Unexpected value Token['Ã'], line 2
   ```

Rozszerzenie CryptoTokenKit z pakietu e-dowód tu nie pomaga: obsługuje Safari, Pęk kluczy
i Chrome, ale aplikacje w Javie korzystają tylko z PKCS#11.

## Rozwiązanie tymczasowe

Skrypt `patch-podpisgov-x64.sh` uruchamia Podpis GOV na **Javie 8 dla Intela przez Rosettę 2**.
Taki proces może już załadować moduł PWPW. Dodatkowo skrypt tworzy dowiązanie do modułu pod
ścieżką bez polskich znaków.

**Nic w `/Applications` nie jest zmieniane**, więc podpisy kodu aplikacji pozostają nienaruszone.

### Wymagania

- Mac z Apple Silicon i macOS.
- Zainstalowany [Podpis GOV](https://www.gov.pl/web/gov/podpisz-dokument-elektronicznie-wykorzystaj-podpis-gov).
- Zainstalowana aplikacja **e-dowód** od PWPW (oprogramowanie do e-dowodu).
- Czytnik obsługujący e-dowód. Przetestowano na ACS ACR122U (NFC).
- Rosetta 2. Jeśli jej brakuje, skrypt zaproponuje instalację (wymaga hasła administratora).

### Instalacja

```bash
zsh patch-podpisgov-x64.sh
```

Skrypt kolejno:

1. Sprawdza wymagania: Apple Silicon, Podpis GOV, moduł PWPW i Rosettę 2.
2. Pobiera **Eclipse Temurin 8 JRE dla macOS x64** (ok. 40 MB) w konkretnej wersji (8u504-b01)
   i weryfikuje jej **sumę SHA-256**. Instaluje ją do `~/Library/Application Support/PodpisGOV-x64/`.
3. Tworzy dowiązanie `/Users/Shared/PodpisGOV-x64/e-dowod-pkcs11-64.dylib` do modułu PWPW.
4. Tworzy aplikację `~/Applications/PodpisGOV-x64.app`, która uruchamia zainstalowany Podpis GOV
   (zawsze najnowszą wersję) na Javie x64.
5. Na koniec wykonuje autotest: ładuje moduł i wyświetla tokeny z e-dowodu.

Przykładowy wynik autotestu (z dowodem na czytniku):

```
Moduł: PWPW S.A. - e-dowod, PKCS#11 API v.4.3.4.28
Czytniki/sloty: 5, z kartą: 5
  slot 0: E-Dowód (Authentication) #0
  slot 1: E-Dowód (Presence) #1
  slot 2: E-Dowód (Authorization) #2
  slot 3: E-Dowód (Qualified) #3
  slot 4: eMRTD #4
```

### Użycie

1. Zamknij zwykły Podpis GOV. Nie uruchamiaj obu wersji jednocześnie.
2. Otwórz `~/Applications/PodpisGOV-x64.app`. Możesz przeciągnąć ją do Docka.
3. Wybierz **Dodaj wystawcę z dysku** i wskaż plik
   `/Users/Shared/PodpisGOV-x64/e-dowod-pkcs11-64.dylib`
   (w oknie wyboru pliku naciśnij **Cmd+Shift+G** i wklej ścieżkę).
   Nie wskazuj ścieżki z `/Applications/e-dowód.app`.
4. Połóż e-dowód na czytniku i przy podpisywaniu podaj PIN.

Nie odinstalowuj oryginalnego Podpis GOV, bo launcher korzysta z jego plików. Aktualizacje
Podpis GOV są wykrywane automatycznie.

### Pozostałe opcje

```bash
zsh patch-podpisgov-x64.sh --check                 # tylko test: czy moduł widzi e-dowód
zsh patch-podpisgov-x64.sh --uninstall             # usuwa wszystko, co skrypt utworzył
zsh patch-podpisgov-x64.sh --jre-tarball PLIK.tar.gz   # instalacja z wcześniej pobranej Javy
```

Skrypt można uruchamiać wielokrotnie: każde kolejne uruchomienie naprawia instalację.

### Ograniczenia

- **Rozwiązanie zależy od Rosetty 2 i przestanie działać po macOS 27**
  (szczegóły i źródła w ostrzeżeniu na górze strony). Przed aktualizacją do następnej wersji
  macOS sprawdź, czy PWPW wydało moduł arm64 — skrypt sam to wykrywa i ostrzega.
- Java x64 instalowana przez skrypt nie aktualizuje się sama. Aby ją odświeżyć, uruchom skrypt
  ponownie po jego aktualizacji.
- Jeśli strona internetowa sama uruchamia Podpis GOV, może wystartować wersja arm64. Zamknij ją
  wtedy i otwórz `PodpisGOV-x64.app`.
- To nieoficjalne obejście, niezwiązane z PWPW ani z COI. Używasz go na własną odpowiedzialność.

## Właściwe rozwiązanie: apel do PWPW i COI

Wystarczy, że **PWPW** wyda moduł `e-dowod-pkcs11` jako **plik uniwersalny (x86_64 + arm64)**.
Najlepiej, żeby dotyczyło to całego pakietu e-dowód i aplikacji „e-dowód Podpis elektroniczny”.

- To jedyny oficjalny moduł PKCS#11 do e-dowodu. Bez wersji arm64 na Macach z Apple Silicon
  nie zadziała z nim żadna natywna aplikacja: Podpis GOV, Firefox, Java, OpenSSL/p11-kit
  ani `pkcs11-tool`.
- Od 2020 roku Apple sprzedaje Maki z Apple Silicon, a od 2023 roku wyłącznie takie.
- Apple kończy obsługę Rosetty: [macOS 27 to ostatnia wersja, w której działają aplikacje
  tylko dla Intela](https://developer.apple.com/news/?id=w5ngl9k2). Bez wersji arm64 moduł
  PWPW po prostu przestanie się uruchamiać.
- Koszt jest niewielki: kompilacja z `-arch x86_64 -arch arm64` (lub złączenie przez `lipo`)
  i ten sam podpis Developer ID oraz notaryzacja.
- Warto przy okazji zainstalować moduł pod ścieżką bez polskich znaków albo udostępnić taki alias.

**COI** może ze swojej strony wykrywać niezgodną architekturę biblioteki i wyświetlać czytelny
komunikat zamiast pustej listy, a docelowo współpracować z PWPW przy testach na Apple Silicon.

e-dowód z kwalifikowanym certyfikatem to najmocniejsza metoda podpisu, jaką ma obywatel.
Powinna działać wszędzie, a jeśli prościej się nie da, to przynajmniej tak prosto.

## Licencja

MIT. Szczegóły w pliku `LICENSE`.
