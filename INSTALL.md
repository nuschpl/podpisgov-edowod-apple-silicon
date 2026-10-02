# Instalacja

[← README](README.md) · **Instalacja** · [Podpisywanie →](RUN.md) · [Architektura](ARCHITEKTURA.md)

> [!WARNING]
> To obejście działa dzięki Rosetcie 2, a Apple kończy jej obsługę na macOS 27.
> Szczegóły w [README](README.md).

> [!IMPORTANT]
> **Na Macu są DWA foldery „Aplikacje”. Nie pomyl ich.**
> - **Aplikacje** (systemowy, `/Applications`, w Finderze na pasku bocznym): tu są zwykły **Podpis GOV**
>   i **e-dowód** od PWPW. **Tego Podpis GOV nie używaj**, bo nie widzi e-dowodu.
> - **Aplikacje w katalogu domowym** (`~/Applications`, Finder → **Idź → Katalog domowy → Aplikacje**):
>   tu jest **PodpisGOV-x64**. **To jest ta właściwa ikona.**

## Wymagania

- Mac z procesorem **Apple Silicon** (M1, M2, M3, M4…). Sprawdzisz to w menu  → **Ten Mac**
  (pozycja *Układ*). Na Macach z Intelem poprawka nie jest potrzebna, a skrypt sam to wykryje.
- Oprogramowanie od dostawców, pobrane z ich oficjalnych stron (stan na październik 2026):

  | Program | Dostawca | Skąd pobrać |
  |---|---|---|
  | **e-dowód** (menedżer e-dowodu, zawiera moduł PKCS#11) | PWPW S.A. | [gov.pl/web/e-dowod](https://www.gov.pl/web/e-dowod) — bezpośrednio: [e-dowod-4.3.4.dmg](https://www.gov.pl/pliki/edowod/e-dowod-4.3.4.dmg) |
  | **Podpis GOV** | COI | [podpis.gov.pl/ui/wp/podpis-gov](https://podpis.gov.pl/ui/wp/podpis-gov) |
  | *(opcjonalnie)* **e-dowód Podpis elektroniczny** | PWPW S.A. | [gov.pl/web/e-dowod](https://www.gov.pl/web/e-dowod) — bezpośrednio: [eDOSign-1.13.13.dmg](https://www.gov.pl/pliki/edowod/eDOSign-1.13.13.dmg) |

  Numery wersji w bezpośrednich linkach mogą się zmienić. Jeśli link nie działa, wejdź na stronę główną dostawcy.
- **Czytnik NFC** obsługujący e-dowód. Przetestowano na ACS ACR122U.
- **Rosetta 2.** Jeśli jej brakuje, skrypt zaproponuje instalację (wymaga hasła administratora).
- Połączenie z internetem do pobrania Javy (ok. 95 MB) i ok. 300 MB wolnego miejsca.

## Jak otworzyć Terminal

Instalacja wymaga wpisania jednego polecenia w Terminalu:

1. Naciśnij **⌘ Cmd + Spacja**, wpisz **Terminal** i naciśnij **Enter**.
2. Skopiuj polecenie z ramki poniżej (ikona kopiowania w prawym górnym rogu ramki),
   wklej je w Terminalu przez **⌘ Cmd + V** i naciśnij **Enter**.

## Pobranie skryptu

**Najprościej — pobranie i instalacja jednym poleceniem:**

```bash
curl -fLO https://raw.githubusercontent.com/nuschpl/podpisgov-edowod-apple-silicon/main/patch-podpisgov-x64.sh && zsh patch-podpisgov-x64.sh
```

Jeśli wolisz najpierw pobrać skrypt i go przejrzeć, wybierz jeden ze sposobów:

**A. Jednym poleceniem w Terminalu**

```bash
curl -fLO https://raw.githubusercontent.com/nuschpl/podpisgov-edowod-apple-silicon/main/patch-podpisgov-x64.sh
```

**B. Przez przeglądarkę**

Otwórz [`patch-podpisgov-x64.sh`](patch-podpisgov-x64.sh), kliknij **Download raw file**
i w Terminalu przejdź do katalogu z pobranym plikiem (zwykle `cd ~/Downloads`).

**C. Całe repozytorium**

```bash
git clone https://github.com/nuschpl/podpisgov-edowod-apple-silicon.git
```

Przed uruchomieniem możesz przejrzeć skrypt. To zwykły tekst w zsh, ok. 160 linii.

## Instalacja

W katalogu ze skryptem uruchom:

```bash
zsh patch-podpisgov-x64.sh
```

Skrypt kolejno:

1. Sprawdza wymagania: Apple Silicon, Podpis GOV, moduł PWPW i Rosettę 2.
2. Pobiera **Azul Zulu 8 JRE z JavaFX dla macOS x64** w konkretnej wersji (8u504, Zulu 8.96),
   weryfikuje jej **sumę SHA-256** i instaluje ją w `~/Library/Application Support/PodpisGOV-x64/`.
3. Tworzy dowiązanie `/Users/Shared/PodpisGOV-x64/e-dowod-pkcs11-64.dylib` do modułu PWPW,
   czyli ścieżkę bez spacji i polskich znaków.
4. Tworzy aplikację `~/Applications/PodpisGOV-x64.app`. Przy każdym starcie aplikacja:
   - poprawia ścieżkę do modułu PWPW w konfiguracji Podpis GOV (`~/.pksigner/config.ini`) na dowiązanie bez „ó”,
     bo inaczej **podpis** kończy się błędem „Library … does not exist”,
   - dodaje wystawcę PWPW, jeśli go tam nie ma, więc nie trzeba go dodawać ręcznie,
   - gdy Podpis GOV już działa, otwiera okno wyboru certyfikatu.
5. Wykonuje autotest: ładuje moduł i wyświetla tokeny z e-dowodu.

**Nic w `/Applications` nie jest zmieniane**, więc podpisy kodu Podpis GOV i aplikacji e-dowód
pozostają nienaruszone.

## Sprawdzenie

Połóż e-dowód na czytniku i uruchom:

```bash
zsh patch-podpisgov-x64.sh --check
```

Poprawny wynik wygląda tak:

```
Moduł: PWPW S.A. - e-dowod, PKCS#11 API v.4.3.4.28
Czytniki/sloty: 5, z kartą: 5
  slot 0: E-Dowód (Authentication) #0
  slot 1: E-Dowód (Presence) #1
  slot 2: E-Dowód (Authorization) #2
  slot 3: E-Dowód (Qualified) #3
  slot 4: eMRTD #4
```

Jeśli widzisz listę podobną do powyższej, wszystko działa. Gdy wynik pokazuje `z kartą: 0`,
dowód nie leży na czytniku albo czytnik go nie widzi.

## Wszystkie opcje

```bash
zsh patch-podpisgov-x64.sh                          # instalacja lub naprawa
zsh patch-podpisgov-x64.sh --check                  # tylko test: czy moduł widzi e-dowód
zsh patch-podpisgov-x64.sh --uninstall              # usuwa wszystko, co skrypt utworzył
zsh patch-podpisgov-x64.sh --jre-tarball PLIK.tar.gz    # instalacja z wcześniej pobranej Javy
zsh patch-podpisgov-x64.sh --help                   # pomoc
```

Skrypt można uruchamiać wielokrotnie. Każde kolejne uruchomienie naprawia instalację i niczego
nie pobiera ponownie, jeśli Java x64 jest już zainstalowana.

## Aktualizacja

- **Podpis GOV:** aktualizuj normalnie. Launcher sam wybiera najnowszą wersję aplikacji.
- **Skrypt i Java x64:** pobierz nową wersję skryptu i uruchom ją ponownie. Aby wymusić świeżą
  Javę, najpierw uruchom `--uninstall`.
- **e-dowód od PWPW:** aktualizuj normalnie. Dowiązanie wskazuje zawsze na aktualny plik. Jeśli PWPW
  wyda moduł w wersji arm64, skrypt to wykryje i poinformuje, że poprawka nie jest już potrzebna.

## Odinstalowanie

```bash
zsh patch-podpisgov-x64.sh --uninstall
```

Usuwa Javę x64, dowiązanie w `/Users/Shared/PodpisGOV-x64` i `~/Applications/PodpisGOV-x64.app`.
Podpis GOV i e-dowód zostają bez zmian. Wpis biblioteki dodany w Podpis GOV usuń w samej aplikacji
przyciskiem **Usuń wystawcę**.

---

Dalej: [Jak podpisać dokument →](RUN.md)
