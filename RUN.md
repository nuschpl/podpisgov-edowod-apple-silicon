# Jak podpisać dokument e-dowodem na Macu

[← README](README.md) · [← Instalacja](INSTALL.md) · **Podpisywanie** · [Rodzaje podpisów →](PODPISY.md) · [Architektura](ARCHITEKTURA.md)

Ta instrukcja jest dla osób, które **mają już zainstalowaną poprawkę** (zobacz [Instalacja](INSTALL.md)).
Nie trzeba tu nic wpisywać w Terminalu.

> [!IMPORTANT]
> **Na Macu są DWA foldery „Aplikacje”. Nie pomyl ich.**
> - **Aplikacje** (systemowy, `/Applications`, w Finderze na pasku bocznym): tu są zwykły **Podpis GOV**
>   i **e-dowód** od PWPW. **Tego Podpis GOV nie używaj**, bo nie widzi e-dowodu.
> - **Aplikacje w katalogu domowym** (`~/Applications`, Finder → **Idź → Katalog domowy → Aplikacje**):
>   tu jest **PodpisGOV-x64**. **To jest ta właściwa ikona.**

## Co musisz mieć przy sobie

- **Dowód osobisty z warstwą elektroniczną** (e-dowód, wydany od marca 2019).
- **Czytnik NFC** podłączony do Maca.
- **Numer CAN** — 6 cyfr w prawym dolnym rogu **przedniej strony** dowodu.
- **PIN2 do podpisu osobistego** — 6 cyfr, ustalony w urzędzie gminy (przy odbiorze dowodu albo później),
  albo **8-cyfrowy PIN** do podpisu kwalifikowanego, jeśli go kupiłeś.

> [!CAUTION]
> Po **3 błędnych próbach** PIN zostaje zablokowany. Jeśli nie pamiętasz PIN-u, nie zgaduj.
> Nowy PIN ustalisz w dowolnym urzędzie gminy.

## Krok 0. Najpierw aplikacja e-dowód

**Kolejność ma znaczenie.** Bezpieczne połączenie z dowodem nawiązuje aplikacja **e-dowód** od PWPW,
a Podpis GOV korzysta z niego dopiero wtedy, gdy jest gotowe.

1. Otwórz aplikację **e-dowód** (zwykły folder Aplikacje) i połóż dowód na czytniku.
2. Jeśli zapyta o **CAN**, wpisz 6 cyfr z przodu dowodu.
3. **Poczekaj na komunikat o odczytaniu certyfikatów.** Na wolniejszych czytnikach NFC trwa to nawet
   20–40 sekund, a czytnik w tym czasie mruga lub daje sygnał. Nie zdejmuj dowodu.

Dopiero potem otwórz Podpis GOV. Jeśli otworzysz go wcześniej, możesz zobaczyć „Nie znaleziono certyfikatów”.
Wtedy poczekaj na komunikat aplikacji e-dowód i kliknij **PodpisGOV-x64** ponownie.

## Krok 1. Otwórz właściwą wersję Podpis GOV

Masz teraz na Macu **dwie ikony** Podpis GOV. Do e-dowodu działa tylko jedna z nich:

| ✅ Używaj tej | ❌ Nie tej |
|---|---|
| **PodpisGOV-x64** w folderze **Aplikacje w Twoim katalogu domowym** | **PodpisGOV** w zwykłym folderze **Aplikacje** |

Jak ją znaleźć:

1. Otwórz **Finder**.
2. Z menu na górze ekranu wybierz **Idź → Katalog domowy**.
3. Otwórz folder **Aplikacje** i kliknij dwukrotnie **PodpisGOV-x64**.

**Rada:** przeciągnij **PodpisGOV-x64** na Dock (pasek ikon na dole ekranu). Następnym razem
wystarczy kliknąć tam.

Jeśli zwykły Podpis GOV jest już otwarty, najpierw go zamknij (patrz [Problemy](#coś-nie-działa)).

## Krok 2. Wystawca e-dowodu (zwykle automatycznie)

**PodpisGOV-x64 sam dodaje wystawcę PWPW** do ustawień Podpis GOV. Zwykle od razu zobaczysz certyfikaty i możesz
przejść do Kroku 3. Poniższe kroki są potrzebne tylko wtedy, gdy na liście wystawców nie ma „PWPW S.A.”.

> [!WARNING]
> Jeśli dodasz wystawcę PWPW ręcznie, **kliknij potem PodpisGOV-x64**. Okno wyboru pliku zapisuje ścieżkę z „ó”,
> a przy niej lista certyfikatów działa, ale podpis kończy się błędem (PIN nie jest wtedy zużywany). PodpisGOV-x64
> wykrywa to, poprawia ścieżkę i proponuje **„Uruchom ponownie”**. Kliknij to przed podpisem.
> Inni wystawcy (np. Certum, tokeny USB) nie są zmieniani.

1. Otwórz okno wyboru certyfikatu. Po uruchomieniu Podpis GOV działa w tle (na górnym pasku widać
   tylko „java” i ikonę z opcją „Wyjście”), więc **kliknij PodpisGOV-x64 jeszcze raz**: otworzy się okno
   z listą wystawców. Okno pojawia się też samo, gdy podpisujesz dokument na stronie gov.pl.
   W tym oknie kliknij **Dodaj nowego wystawcę**, a potem **Dodaj wystawcę z dysku**.
2. Otworzy się okno wyboru pliku. Naciśnij razem klawisze **⌘ Cmd + ⇧ Shift + G**.
3. W okienku, które się pojawi, wklej poniższy tekst i naciśnij **Enter**:

   ```
   /Users/Shared/PodpisGOV-x64/e-dowod-pkcs11-64.dylib
   ```

4. Kliknij **Otwórz** (lub **Wybierz**).

> [!IMPORTANT]
> Oficjalna instrukcja COI każe wskazać plik w folderze `/Applications/e-dowód.app/…`.
> **Na Macach z Apple Silicon to nie zadziała** — wklej dokładnie ścieżkę podaną wyżej.

## Krok 3. Podpisz dokument

1. Otwórz aplikację **e-dowód** (zwykły folder Aplikacje), połóż e-dowód na czytniku
   i **nie zdejmuj go** aż do końca. Jeśli aplikacja poprosi o **numer CAN**, wpisz 6 cyfr z przodu dowodu.
   Bez tego Podpis GOV nie zobaczy certyfikatów.
2. Przejdź do usługi, w której podpisujesz dokument, np. [podpis.gov.pl](https://podpis.gov.pl/ui/wp/podpis-gov).
   Wybór na stronie „Podpisz dokument”:

   | Chcesz złożyć | Wybierz na gov.pl | PIN |
   |---|---|---|
   | **podpis osobisty** | **E-dowód → Podpis osobisty e-dowodem** | PIN2, 6 cyfr |
   | **podpis kwalifikowany** (także ten **na e-dowodzie**) | **Certyfikat kwalifikowany** (osobna pozycja na pierwszym ekranie, **nie** pod „E-dowód”) | 8 cyfr |
   | podpis zaufany potwierdzony e-dowodem | E-dowód → Podpis zaufany | PIN1, 4 cyfry (nie przez Podpis GOV) |

   Strona sama połączy się z otwartym Podpis GOV.
3. Jeśli aplikacja **e-dowód** ponownie poprosi o **numer CAN**, przepisz 6 cyfr z przodu dowodu.
4. W Podpis GOV kliknij **certyfikat ze swoim imieniem i nazwiskiem** (podpis osobisty),
   a potem **Wybierz certyfikat**. Jeśli masz dokupiony certyfikat kwalifikowany, możesz wybrać ten.
   Nie wiesz, który wybrać? Zobacz [Jaki podpis wybrać?](PODPISY.md)
5. Wpisz PIN i kliknij **Akceptuję**: **6 cyfr (PIN2)** dla podpisu osobistego albo **8 cyfr**
   dla podpisu kwalifikowanego.

Gotowe. Strona pokaże podpisany dokument do pobrania.

## Coś nie działa?

**Widzę „Nie znaleziono certyfikatów”**
- Najczęstsza przyczyna: aplikacja **e-dowód** nie skończyła jeszcze odczytu (Krok 0). Poczekaj na jej komunikat
  o odczytanych certyfikatach i kliknij **PodpisGOV-x64** ponownie.
- Upewnij się, że otworzyłeś **PodpisGOV-x64**, a nie zwykły Podpis GOV (Krok 1).
- Sprawdź, czy dowód leży na czytniku, a czytnik jest podłączony.
- Upewnij się, że w Kroku 2 wkleiłeś dokładnie podaną ścieżkę.

**Lista wystawców nagle pusta / „Nie znaleziono certyfikatów” mimo że wcześniej działało**
Błąd w Podpis GOV: w niektórych sytuacjach (np. podpis kwalifikowany z podpisywarki gov.pl, ręczne „Dodaj wystawcę”)
aplikacja nie wczytuje modułu i zapisuje pustą listę wystawców. Kliknij **PodpisGOV-x64**: odtworzy wystawcę
i zaproponuje **„Uruchom ponownie”**. Potem ponów podpis na stronie. Podpis kwalifikowany możesz też złożyć
w aplikacji **e-dowód Podpis elektroniczny** od PWPW.

**Podpis kwalifikowany: po PIN-ie „Wystąpił błąd i dokument nie został podpisany”**
Jeśli Twój certyfikat kwalifikowany na e-dowodzie był **odnawiany**, na karcie zostaje też stary, wygasły certyfikat,
a Podpis GOV myli je przy podpisie. PIN nie jest przy tym blokowany. Podpis kwalifikowany złożysz w aplikacji
**e-dowód Podpis elektroniczny** od PWPW. Podpis osobisty przez gov.pl działa normalnie.

**Okno „Error … Port 8640 is already in use”**
Uruchomiła się druga kopia Podpis GOV (np. podwójne kliknięcie w trakcie startu). Kliknij **OK**: pierwsza kopia działa
dalej. Nowsza wersja PodpisGOV-x64 czeka na startującą kopię i nie uruchamia drugiej. Zaktualizuj skrypt, jeśli to widzisz.

**Kliknięcie nie otwiera okna Podpis GOV**
- Klikaj aplikację **PodpisGOV-x64** z folderu *Aplikacje* w katalogu domowym albo jej ikonę przypiętą do Docka.
  Ikona **działającego** Podpis GOV w Docku wygląda tak samo, ale kliknięcie jej nic nie robi.
- Zawsze działa też polecenie w Terminalu (gdy Podpis GOV jest uruchomiony):

  ```bash
  curl -sk -H 'Origin: https://podpis.gov.pl' 'https://127.0.0.1:8640/rest/certificates?pc=0' >/dev/null &
  ```

  `pc=0` otwiera okno w trybie **podpisu kwalifikowanego**, a `pc=1` najpewniej w trybie **podpisu osobistego**
  (tak wskazuje log aplikacji). Strona gov.pl sama wybiera tryb przy podpisywaniu.

**Strona gov.pl sama otworzyła Podpis GOV i nie widać certyfikatów**
Strona uruchomiła zwykłą wersję. Zamknij ją, otwórz **PodpisGOV-x64** i odśwież stronę.

**Podpis GOV się zawiesił i nie mogę go zamknąć**
1. Otwórz **Monitor aktywności** (Finder → Aplikacje → Narzędzia).
2. W polu wyszukiwania w prawym górnym rogu wpisz **java**.
   Podpis GOV jest tam widoczny jako „java”, a nie pod swoją nazwą.
3. Zaznacz ten wiersz, kliknij przycisk **✕** u góry okna i wybierz **Wymuś koniec**.

**macOS wyświetla ostrzeżenie o aplikacji dla procesorów Intel**
To komunikat Apple o kończącym się wsparciu Rosetty. Możesz go zamknąć i podpisywać dalej.
Dlaczego się pojawia — zobacz [README](README.md).

**Zablokowałem PIN**
Odblokujesz go kodem PUK (otrzymanym razem z dowodem) albo ustalisz nowy PIN w dowolnym urzędzie gminy.

**Nadal nie działa?**
Zgłoś problem w [Issues](https://github.com/nuschpl/podpisgov-edowod-apple-silicon/issues).
Napisz, jaką masz wersję macOS (menu  → Ten Mac) i co dokładnie widać na ekranie.
Nie wpisuj tam numeru CAN, PIN-u ani danych z dowodu.
