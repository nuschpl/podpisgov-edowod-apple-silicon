# Architektura: kto rozmawia z e-dowodem

[← README](README.md) · [Instalacja](INSTALL.md) · [Podpisywanie](RUN.md) · [Rodzaje podpisów](PODPISY.md) · **Architektura**

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

   | Slot | Token | PIN |
   |---|---|---|
   | 0 | E-Dowód (Authentication) | 4 cyfry (PIN1) |
   | 1 | E-Dowód (Presence) | brak |
   | 2 | E-Dowód (Authorization): podpis osobisty | 6 cyfr (PIN2) |
   | 3 | E-Dowód (Qualified): podpis kwalifikowany, jeśli kupiony | 8 cyfr |
   | 4 | eMRTD (dane paszportowe) | brak (CAN) |

3. **Bez tej sesji moduł widzi tylko czytnik.** Zwraca wtedy 1 slot i `CKR_TOKEN_NOT_PRESENT`, mimo że
   dowód leży na czytniku. Czytnik tylko krótko mrugnie (ok. 2 s, odczyt ATR) i nic więcej się nie dzieje.
   Podpis GOV pokazuje wówczas „Nie znaleziono certyfikatów” bez żadnej wskazówki.

Do tej samej karty sięga też **rozszerzenie CryptoTokenKit** od PWPW, czyli systemowy dostęp macOS dla
Safari, Pęku kluczy i Chrome. Trzy komponenty jednego dostawcy korzystają z jednej karty i jednego wolnego
łącza NFC, więc kolejność ma znaczenie.

## Właściwa kolejność

1. **Aplikacja e-dowód:** połóż dowód, wpisz CAN i poczekaj na komunikat o odczytanych certyfikatach.
   Na wolnym czytniku (np. ACR122U) trwa to 20–40 sekund, a czytnik w tym czasie daje sygnał i mruga.
2. **Podpis GOV** (przez `PodpisGOV-x64.app`). Okno z opcją „Dodaj wystawcę” otworzysz, klikając
   `PodpisGOV-x64` ponownie, gdy aplikacja już działa.
3. **Strona gov.pl** łączy się z Podpis GOV przez `https://localhost:8640` i prosi o podpis.

## Gdzie działa nasze obejście

Obejście z tego repozytorium dotyczy wyłącznie kroku 2. Podpis GOV ma wbudowaną Javę dla Apple Silicon
(arm64), a moduł PWPW istnieje tylko dla procesorów Intel (x86_64). Skrypt uruchamia więc Podpis GOV
na Javie x64 z JavaFX (Azul Zulu 8) przez Rosettę 2. Kroki 1 i 3 działają bez zmian.

Szczegóły techniczne: [README — Przyczyna](README.md#przyczyna).

## Jak to sprawdzono

- Długości PIN-ów i flagi tokenów odczytano z karty **bez wpisywania PIN-u** (`ulMinPinLen` / `ulMaxPinLen`):
  `zsh tools/test-podpisow.sh` (krok 1).
- Brak tokenów przed zakończeniem odczytu w aplikacji e-dowód i 5 tokenów po nim:
  `zsh patch-podpisgov-x64.sh --check`.
- Zatrzymanie samego rozszerzenia CryptoTokenKit nie pomaga. Moduł potrzebuje sesji aplikacji e-dowód.

Ikony aplikacji na diagramie należą do PWPW S.A. (e-dowód) i COI (Podpis GOV). Użyto ich wyłącznie do
identyfikacji aplikacji.
