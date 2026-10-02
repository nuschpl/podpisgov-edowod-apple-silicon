# Jaki podpis wybrać? Proste porównanie

[← README](README.md) · [Instalacja](INSTALL.md) · [Podpisywanie](RUN.md) · **Rodzaje podpisów** · [Architektura](ARCHITEKTURA.md)

Ta strona jest dla osób, które nie są ani prawnikami, ani informatykami. Wyjaśnia, czym różnią się
podpisy, które możesz złożyć e-dowodem lub przez gov.pl, i **kiedy który wystarczy**.

> [!NOTE]
> To praktyczne wyjaśnienie, nie porada prawna. Gdy od podpisu zależy coś ważnego (umowa,
> pełnomocnictwo, sprawa sądowa), zapytaj drugą stronę albo prawnika, jaki podpis jest wymagany.

## Najkrótsza odpowiedź

- **Sprawy urzędowe** (gov.pl, ZUS, urząd skarbowy, gmina): wystarczy **podpis osobisty**
  albo **podpis zaufany**. Oba są bezpłatne.
- **Umowy i pisma do firm lub osób prywatnych**: tylko **podpis kwalifikowany** zawsze
  i wszędzie zastępuje podpis odręczny. Pozostałe działają tylko wtedy, gdy druga strona je przyjmie.

## Porównanie

| | **Podpis zaufany** | **Podpis osobisty** | **Podpis kwalifikowany** |
|---|---|---|---|
| Czym jest | Podpis przez Profil Zaufany, w internecie | Certyfikat zapisany w e-dowodzie | Płatny certyfikat kwalifikowany (np. w e-dowodzie) |
| Potrzebujesz | Profilu Zaufanego (np. przez bank) i telefonu | e-dowodu, czytnika NFC lub telefonu z NFC | certyfikatu kupionego u dostawcy i nośnika (np. e-dowodu) |
| Czym potwierdzasz | Kodem z SMS-a lub aplikacją | **PIN2 — 6 cyfr** | **PIN do certyfikatu kwalifikowanego — 8 cyfr** (w e-dowodzie) |
| Koszt | Bezpłatny | Bezpłatny | Płatny |
| Sprawy urzędowe w Polsce | ✅ Tak | ✅ Tak | ✅ Tak |
| Umowy z firmami i osobami prywatnymi | ⚠️ Tylko jeśli druga strona się zgodzi | ⚠️ Tylko jeśli druga strona się zgodzi | ✅ **Tak — jak podpis odręczny** |
| Inne kraje UE | ❌ Zwykle nie | ❌ Zwykle nie | ✅ **Tak** |
| Działa z tym repozytorium | — (nie wymaga czytnika) | ✅ Tak | ✅ Tak, jeśli certyfikat jest w e-dowodzie |

### Dlaczego tylko kwalifikowany jest „jak odręczny” wszędzie

Prawo UE ([rozporządzenie eIDAS, art. 25 ust. 2](https://eur-lex.europa.eu/legal-content/PL/TXT/?uri=CELEX:32014R0910))
i polski Kodeks cywilny (art. 78¹) mówią wprost, że **kwalifikowany podpis elektroniczny ma taki
sam skutek prawny jak podpis własnoręczny**. Dotyczy to umów z każdym, w całej Unii.

Podpis osobisty i podpis zaufany są równoważne odręcznemu przede wszystkim **w kontaktach
z urzędami**. Firma lub osoba prywatna może ich nie przyjąć.

## Kody w e-dowodzie: co jest czym

W kopercie i w urzędzie spotkasz kilka kodów. Łatwo je pomylić:

| Kod | Długość | Do czego służy | Skąd go masz |
|---|---|---|---|
| **CAN** | 6 cyfr | Połączenie z dowodem przez NFC | Nadrukowany na **przedniej stronie** dowodu, w prawym dolnym rogu |
| **PIN1** | 4 cyfry | **Logowanie** i potwierdzanie tożsamości (profil osobisty). To **nie** jest podpis. | Ustalasz w urzędzie gminy |
| **PIN2** | 6 cyfr | **Podpis osobisty** | Ustalasz w urzędzie gminy |
| **PUK** | 8 cyfr | **Odblokowanie** PIN1 i PIN2 po 3 błędnych próbach | W **kopercie** wydanej razem z dowodem |
| **PIN do podpisu kwalifikowanego** | 8 cyfr | **Podpis kwalifikowany** | Ustalasz przy aktywacji kupionego certyfikatu |

> [!TIP]
> Długości PIN-ów potwierdziła sama karta (e-dowód, oprogramowanie PWPW 4.3.4.28): token *Authentication*
> wymaga **4 cyfr** (PIN1), *Authorization* (podpis osobisty) **6 cyfr** (PIN2), a *Qualified*
> (podpis kwalifikowany) **8 cyfr**. Sprawdzisz to u siebie bez wpisywania PIN-u, uruchamiając
> `tools/test-podpisow.sh` (krok 1).

**Ważne o PIN1 i PIN2:** ustalasz je w urzędzie gminy, najczęściej przy odbiorze dowodu.
Jeśli wtedy tego nie zrobiłeś, możesz to zrobić **później w dowolnym urzędzie gminy**. Bez tego
nie zalogujesz się dowodem (PIN1) ani nie złożysz podpisu osobistego (PIN2).

**Schowaj kopertę z kodem PUK.** Trzy błędne próby PIN-u blokują certyfikat, a PUK pozwala go
odblokować bez wizyty w urzędzie, np. w aplikacji mObywatel. Nikomu nie podawaj PIN-ów ani PUK-u.

## Jak zdobyć podpis kwalifikowany w e-dowodzie

Certyfikat kwalifikowany do e-dowodu sprzedaje **PWPW** przez swoje centrum usług zaufania
**[Sigillum](https://sigillum.pl/)**. Po zakupie i aktywacji certyfikat trafia do warstwy
elektronicznej Twojego dowodu. Podpisujesz nim:
- na komputerze: przez program **e-dowód** od PWPW, czytnik NFC i aplikację podpisującą
  (np. Podpis GOV, na Macu z Apple Silicon razem z [tą poprawką](INSTALL.md)),
- na telefonie: przez aplikację **[eDO App](https://www.gov.pl/web/e-dowod)** od PWPW.

Szczegóły, ceny i okres ważności certyfikatu znajdziesz u dostawcy:
[sigillum.pl](https://sigillum.pl/).

## Źródła

- [gov.pl — „Czekasz na e-dowód? Pomyśl nad PIN-em”](https://www.gov.pl/web/cyfryzacja/czekasz-na-e-dowod-pomysl-nad-pin-em)
- [gov.pl — zmiana PIN2 i odblokowanie certyfikatu e-dowodu](https://www.gov.pl/web/cyfryzacja/podpisz-dokument--zmiana-pin2-i-odblokowanie-certyfikatu-e-dowodu)
- [gov.pl — e-dowód](https://www.gov.pl/web/e-dowod)
- [PWPW Sigillum — podpis kwalifikowany w e-dowodzie](https://sigillum.pl/aktualnosci/Edo_app)
- [Instrukcja COI — podpis osobisty w systemie e-podpis (PDF)](https://pz.gov.pl/ep-frontend/assets/download/ePodpis_-_Instrukcja_uzytkownika_podpis_osobisty.pdf)
