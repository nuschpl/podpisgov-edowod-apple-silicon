#!/bin/zsh
# patch-podpisgov-x64.sh — uruchamia Podpis GOV (COI) z e-dowodem na Macach z Apple Silicon.
#
# Problem: Podpis GOV ma wbudowaną Javę arm64, a moduł PKCS#11 e-dowodu od PWPW
# (/Applications/e-dowód.app/Contents/lib/e-dowod-pkcs11-64.dylib) istnieje tylko dla x86_64,
# więc nie da się go załadować ("incompatible architecture"). Java 8 nie akceptuje też
# litery "ó" w ścieżce modułu.
#
# Rozwiązanie (nic w /Applications nie jest zmieniane):
#   1. pobranie Eclipse Temurin 8 JRE dla macOS x64 (stała wersja, weryfikacja SHA-256)
#   2. dowiązanie do modułu PWPW pod ścieżką bez polskich znaków
#   3. aplikacja uruchamiająca jar Podpis GOV na tej Javie przez Rosettę 2
#
# Użycie:
#   zsh patch-podpisgov-x64.sh                       instalacja / naprawa (można powtarzać)
#   zsh patch-podpisgov-x64.sh --check               tylko test: czy moduł widzi e-dowód
#   zsh patch-podpisgov-x64.sh --uninstall           usuwa wszystko, co utworzył skrypt
#   zsh patch-podpisgov-x64.sh --jre-tarball PLIK    instalacja z wcześniej pobranej Javy
#
# Potem: zamknij Podpis GOV, otwórz ~/Applications/PodpisGOV-x64.app i w
# "Dodaj wystawcę z dysku" wskaż ścieżkę biblioteki wypisaną na końcu.

set -euo pipefail

JRE_VER=8u504b01
JRE_DIR_NAME=jdk8u504-b01-jre
JRE_FILE=OpenJDK8U-jre_x64_mac_hotspot_${JRE_VER}.tar.gz
JRE_URL=https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u504-b01/$JRE_FILE
JRE_SHA256=f06abadad0fa97e04866d7229a2baad53261579ab5d44875ffa8846a28f28d86

PODPISGOV=/Applications/PodpisGOV.app
EDOWOD_LIB="/Applications/e-dowód.app/Contents/lib/e-dowod-pkcs11-64.dylib"

BASE="$HOME/Library/Application Support/PodpisGOV-x64"
JAVA_HOME_X64="$BASE/$JRE_DIR_NAME/Contents/Home"
LIB_LINK=/Users/Shared/PodpisGOV-x64/e-dowod-pkcs11-64.dylib   # widoczna, bez spacji i polskich znaków
LAUNCHER="$BASE/PodpisGOV-x64.command"
APP="$HOME/Applications/PodpisGOV-x64.app"

say()  { print -P "%F{cyan}==>%f $*"; }
ok()   { print -P "%F{green}OK%f  $*"; }
warn() { print -P "%F{yellow}!!%f  $*"; }
die()  { print -P "%F{red}BŁĄD%f $*" >&2; exit 1; }

uninstall() {
  rm -rf "$BASE" "$APP" "${LIB_LINK:h}"
  ok "Usunięto $BASE, $APP oraz ${LIB_LINK:h}"
  ok "Sam Podpis GOV nie został zmieniony. Ustawienia dodane w aplikacji (wystawcy) pozostają."
}

check_card() {
  [[ -x "$JAVA_HOME_X64/bin/jjs" ]] || die "Java x64 nie jest jeszcze zainstalowana — uruchom najpierw skrypt bez --check."
  local js; js=$(mktemp -t p11slots).js
  cat > "$js" <<'EOF'
var W = Packages.sun.security.pkcs11.wrapper;
var a = new W.CK_C_INITIALIZE_ARGS(); a.flags = W.PKCS11Constants.CKF_OS_LOCKING_OK;
var p = W.PKCS11.getInstance(arguments[0], "C_GetFunctionList", a, false);
var i = p.C_GetInfo();
print("Moduł: " + String(new java.lang.String(i.manufacturerID)).trim() + ", " + String(new java.lang.String(i.libraryDescription)).trim());
var s = p.C_GetSlotList(false), t = p.C_GetSlotList(true);
print("Czytniki/sloty: " + s.length + ", z kartą: " + t.length);
for (var k = 0; k < t.length; k++) {
  var ti = p.C_GetTokenInfo(t[k]);
  print("  slot " + t[k] + ": " + new java.lang.String(new java.lang.String(ti.label).getBytes("ISO-8859-1"), "UTF-8").trim());
}
EOF
  arch -x86_64 "$JAVA_HOME_X64/bin/jjs" -J-Dfile.encoding=UTF-8 "$js" -- "$LIB_LINK" 2>&1 | grep -vE '^\s+at ' || true
  rm -f "$js" "${js%.js}"
}

# ---------------------------------------------------------------- argumenty
TARBALL=""
case "${1:-}" in
  --uninstall) uninstall; exit 0 ;;
  --check)     check_card; exit 0 ;;
  --jre-tarball) TARBALL="${2:?--jre-tarball wymaga ścieżki do pliku}" ;;
  "") ;;
  -h|--help) sed -n '2,21p' "$0"; exit 0 ;;
  *) die "Nieznana opcja: $1 (zobacz --help)" ;;
esac

# ---------------------------------------------------------------- wymagania
say "Sprawdzam wymagania"
[[ "$(uname -s)" == Darwin ]] || die "Skrypt działa tylko na macOS."
if [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" != 1 ]]; then
  die "Ten Mac ma procesor Intel — Podpis GOV powinien załadować moduł bez poprawek."
fi
[[ -d "$PODPISGOV" ]] || die "Nie znaleziono Podpis GOV w $PODPISGOV (zainstaluj go najpierw ze strony gov.pl)."
[[ -f "$EDOWOD_LIB" ]] || die "Nie znaleziono oprogramowania e-dowodu ($EDOWOD_LIB). Zainstaluj najpierw aplikację 'e-dowód' od PWPW."
ls "$PODPISGOV/Contents/Resources/Java"/podpisgov-*-runnable.jar >/dev/null 2>&1 \
  || die "Nie znaleziono pliku jar Podpis GOV — nieobsługiwana wersja lub układ aplikacji."
if lipo -archs "$EDOWOD_LIB" 2>/dev/null | grep -qw arm64; then
  warn "Moduł PWPW zawiera już wersję arm64 — ta poprawka może nie być potrzebna."
fi
if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
  warn "Rosetta 2 nie jest zainstalowana, a jest wymagana (tłumacz x86_64 od Apple)."
  read -q "?Zainstalować teraz Rosettę 2 (wymaga hasła administratora i akceptuje licencję Apple)? [y = tak / N] " || die "Rosetta 2 jest wymagana."
  echo
  sudo softwareupdate --install-rosetta --agree-to-license
fi
ok "Jest: macOS arm64, Rosetta 2, Podpis GOV i moduł e-dowodu od PWPW"

# ---------------------------------------------------------------- Java x64
mkdir -p "$BASE"
if [[ -x "$JAVA_HOME_X64/bin/java" ]]; then
  ok "Java x64 jest już zainstalowana"
else
  if [[ -z "$TARBALL" ]]; then
    TARBALL="$BASE/$JRE_FILE"
    say "Pobieram Temurin JRE $JRE_VER (x64, ok. 40 MB) z GitHub/Adoptium"
    curl -fL --progress-bar -o "$TARBALL" "$JRE_URL"
  fi
  say "Sprawdzam sumę SHA-256"
  echo "$JRE_SHA256  $TARBALL" | shasum -a 256 -c - >/dev/null || die "Niezgodna suma kontrolna — przerywam."
  tar -xzf "$TARBALL" -C "$BASE"
  [[ "$TARBALL" == "$BASE/$JRE_FILE" ]] && rm -f "$TARBALL"
  file "$JAVA_HOME_X64/bin/java" | grep -q x86_64 || die "Nieoczekiwana architektura pobranej Javy."
  ok "Java x64 zainstalowana w $BASE"
fi

# ---------------------------------------------------------------- dowiązanie do modułu
mkdir -p "${LIB_LINK:h}"
ln -sfn "$EDOWOD_LIB" "$LIB_LINK"
ok "Dowiązanie do modułu: $LIB_LINK"

# ---------------------------------------------------------------- launcher
cat > "$LAUNCHER" <<EOF
#!/bin/zsh
# Podpis GOV na Javie 8 x86_64 (Rosetta), aby mógł załadować moduł PKCS#11 e-dowodu od PWPW (x86_64).
APP=$PODPISGOV/Contents
JAR=\$(ls "\$APP/Resources/Java"/podpisgov-*-runnable.jar | sort -V | tail -1)
cd "\$APP/Resources" || exit 1
exec arch -x86_64 "$JAVA_HOME_X64/bin/java" -cp ".:Java/\${JAR:t}" \\
  -Xdock:icon="\$APP/Resources/PodpisGOV.icns" -Xdock:name="PodpisGOV (x64)" \\
  -Djdk.gtk.version=2 pl.gov.coi.signer.Main "\$@"
EOF
chmod +x "$LAUNCHER"

mkdir -p "${APP:h}"
rm -rf "$APP"
osacompile -o "$APP" -e "do shell script quoted form of \"$LAUNCHER\" & \" >/dev/null 2>&1 &\"" 2>/dev/null
cp "$PODPISGOV/Contents/Resources/PodpisGOV.icns" "$APP/Contents/Resources/applet.icns" 2>/dev/null || true
touch "$APP"
ok "Aplikacja uruchamiająca: $APP"

# ---------------------------------------------------------------- autotest
say "Autotest: ładuję moduł e-dowodu w Javie x64 (do pełnego testu połóż dowód na czytniku)"
check_card

cat <<EOF

Gotowe. Dalsze kroki:
  1. Zamknij zwykły Podpis GOV (nie uruchamiaj obu wersji jednocześnie).
  2. Otwórz  $APP   (możesz przeciągnąć ją do Docka).
  3. "Dodaj wystawcę z dysku" -> wskaż ten plik (w oknie wyboru Cmd+Shift+G i wklej ścieżkę):
       $LIB_LINK
  4. Połóż e-dowód na czytniku i przy podpisywaniu podaj PIN.
Cofnięcie zmian: zsh $0 --uninstall
EOF
