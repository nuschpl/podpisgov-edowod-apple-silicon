#!/bin/zsh
# test-podpisow.sh — interaktywny test PIN-ów i podpisów e-dowodu (uruchamiaj SAMODZIELNIE w Terminalu).
#  1. bez PIN-u: pokazuje tokeny, wymagane długości PIN-ów, flagi prób i certyfikaty,
#  2. dla wybranych tokenów: prosi o PIN (ukryte pole w Javie), loguje się i podpisuje losowe dane.
# PIN nie przechodzi przez powłokę, nie trafia do argumentów procesu ani do plików.
# Błędna długość PIN-u jest odrzucana lokalnie (próba nie przepada). Przy "ostatniej próbie" test jest pomijany.
set -u
HERE="${0:A:h}"
LIB=/Users/Shared/PodpisGOV-x64/e-dowod-pkcs11-64.dylib
JJS=$(ls "$HOME/Library/Application Support/PodpisGOV-x64"/zulu8*-macosx_x64/Contents/Home/bin/jjs 2>/dev/null | tail -1)
[[ -t 0 ]] || { echo "Uruchom ten skrypt bezpośrednio w Terminalu."; exit 1; }
[[ -x "$JJS" && -e "$LIB" ]] || { echo "Najpierw zainstaluj poprawkę: zsh patch-podpisgov-x64.sh"; exit 1; }
run() { arch -x86_64 "$JJS" -J-Dfile.encoding=UTF-8 "$@" 2>&1 | grep -vE '^\s+at |^Exception in thread|^Caused by' }

cat <<'TXT'
Test PIN-ów i podpisów e-dowodu
- Trzy błędne PIN-y blokują dany certyfikat (odblokowanie: PUK z koperty).
- Skrypt odrzuca lokalnie PIN o złej długości — taka pomyłka nie zużywa próby.
- Podpisywane są tylko losowe dane testowe, nie dokument.
- Aplikacja e-dowód może poprosić o numer CAN (6 cyfr z przodu dowodu).
TXT
echo "\n--- Krok 1: informacje z karty (bez PIN-u) ---"
INFO=$(run "$HERE/p11info.js" -- "$LIB")
print -r -- "$INFO"

echo "\n--- Krok 2: test podpisu ---"
slots=( $(print -r -- "$INFO" | sed -nE 's/^slot ([0-9]+): .*/\1/p') )
for s in $slots; do
  name=$(print -r -- "$INFO" | sed -nE "s/^slot $s: (.*)/\1/p")
  [[ "$name" == *eMRTD* || "$name" == *Presence* ]] && { echo "Pomijam: $name (nie wymaga PIN-u / nie służy do podpisu)"; continue; }
  read -q "?Testować „$name”? [y = tak / N] " || { echo; continue; }
  echo
  arch -x86_64 "$JJS" -J-Dfile.encoding=UTF-8 "$HERE/p11sign.js" -- "$LIB" "$s" 2>&1 | grep -vE '^\s+at |^Exception in thread|^Caused by'
done
echo "\nKoniec. Wynik nie zawiera PIN-ów. Przed wklejeniem go gdziekolwiek sprawdź, czy nie ma w nim Twoich danych osobowych."
