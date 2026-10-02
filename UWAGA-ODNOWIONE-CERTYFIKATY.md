# Uwaga: odnowiony certyfikat kwalifikowany na e-dowodzie

[← README](README.md) · [Architektura](ARCHITEKTURA.md) · **Odnowione certyfikaty**

Jeśli Twój certyfikat kwalifikowany na e-dowodzie był **odnawiany**, podpis kwalifikowany przez **Podpis GOV**
(np. na podpis.gov.pl) może kończyć się błędem *„Wystąpił błąd i dokument nie został podpisany”*, mimo że wybrałeś
ważny certyfikat i wpisałeś poprawny PIN. **PIN nie jest przy tym blokowany.** Problem nie zależy od systemu
(dotyczy też Windows) ani od obejścia z tego repozytorium.

**Co działa:** podpis kwalifikowany w aplikacji **e-dowód Podpis elektroniczny** od PWPW oraz podpis osobisty przez gov.pl.

## Na czym polega problem

**1. Co jest na karcie (slot *Qualified*)**

- jedna para kluczy (prywatny i publiczny),
- **dwa certyfikaty na ten sam klucz**: stary, wygasły (np. *CUZ Sigillum – QCA1*) i nowy, ważny (*QCA2*),
- wszystkie te obiekty mają ten sam identyfikator `CKA_ID`. W PKCS#11 to on łączy klucz z jego certyfikatami.

Odnowienie dopisało nowy certyfikat na ten sam klucz, ale nie usunęło starego. Moduł PWPW zwraca obiekty w kolejności
zapisu: najpierw starszy, potem nowszy. To jest „pierwszy z góry”.

**2. Okno wyboru: Podpis GOV czyta kartę jednym sposobem**

Listę certyfikatów Podpis GOV buduje przez API IAIK i przegląda **każdy certyfikat osobno**. Wygasły pomija
(w logu: *„Przeterminowany certyfikat”*) i pokazuje tylko ważny. Wybierasz ważny, a Podpis GOV zapamiętuje jego numer seryjny.

**3. Podpis: Podpis GOV czyta kartę innym sposobem**

Do samego podpisu Podpis GOV (przez bibliotekę EU DSS) używa Java SunPKCS11 i jej `KeyStore`. `KeyStore` to model
„wpisów”, w którym **każdy klucz prywatny ma przypięty dokładnie jeden certyfikat**. Java szuka certyfikatów z tym
samym `CKA_ID` co klucz, znajduje dwa i przypina **pierwszy, który zwróci karta**, czyli wygasły. Ważny certyfikat
nie trafia do żadnego wpisu z kluczem.

**4. Porównanie, które musi się nie udać**

Po zalogowaniu PIN-em (dlatego PIN jest przyjęty i karta nie liczy błędnej próby) Podpis GOV szuka we wpisach
`KeyStore` certyfikatu o numerze seryjnym wybranego, ważnego certyfikatu. Jedyny wpis z kluczem ma numer starego
certyfikatu, więc pojawia się błąd *„Nie znaleziono wybranego ceryfikatu”*, a strona pokazuje
*„Wystąpił błąd i dokument nie został podpisany”*.

```
karta:      [klucz] ── CKA_ID ──┬── certyfikat QCA1 (wygasły)  ← pierwszy z góry
                                └── certyfikat QCA2 (ważny)

lista:      QCA1 pominięty (wygasły) → pokazany QCA2 → wybrany QCA2
podpis:     KeyStore: klucz + QCA1 (jeden certyfikat na klucz)
porównanie: szukam QCA2 we wpisach KeyStore → brak → błąd
```

## Analogia

W szufladzie leży **jeden klucz z dwiema przywieszkami**: starą i nową. Okienko informacji (lista certyfikatów)
pokazuje Ci nową przywieszkę i to ją wybierasz. Magazyn (`KeyStore`) pozwala jednak tylko na **jedną przywieszkę
na klucz** i zostawia tę, która leżała na wierzchu, czyli starą. Magazynier szuka klucza z nową przywieszką i odpowiada,
że takiego nie ma, choć to ten sam klucz.

## Kto może to naprawić

| Strona | Co | Gdzie zgłoszone |
|---|---|---|
| **COI** (główna przyczyna) | Przy podpisie szukać klucza po `CKA_ID` certyfikatu wybranego przez użytkownika (tak jak przy liście), zamiast porównywać numer seryjny certyfikatu przypiętego w `KeyStore`. Wtedy kolejność certyfikatów na karcie przestaje mieć znaczenie. | zgłoszenie do COI, pkt 2c i 2d |
| **Java SunPKCS11** | „Jeden certyfikat na klucz” to założenie modelu `KeyStore`, nie błąd. Naprawa należy do aplikacji. | — |
| **PWPW** | Po odnowieniu usuwać wygasły certyfikat (wtedy na karcie jest jeden kandydat). Według punktu sprzedaży Sigillum usunąć go może tylko PWPW. | list do PWPW, pkt 4 |

**Dlaczego aplikacja PWPW działa:** ma własny wrapper PKCS#11 i nie korzysta z modelu `KeyStore`
„jeden certyfikat na klucz”, więc używa dokładnie tego certyfikatu, który wybierasz.

## Jak sprawdzić, czy Cię to dotyczy

Na liście certyfikatów w **e-dowód Podpis elektroniczny** albo w logu Podpis GOV (`~/.pksigner/application.log`)
zobaczysz dwa certyfikaty kwalifikowane od Sigillum, w tym jeden przeterminowany. Komunikat w logu Podpis GOV
przy nieudanym podpisie: `Nie znaleziono wybranego ceryfikatu`.
