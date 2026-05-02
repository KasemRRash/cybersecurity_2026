#!/bin/sh
# Vollstaendiger Anforderungstest fuer die Java-Loesung.
set -eu
# -e: bei Fehlern abbrechen; -u: nicht gesetzte Variablen als Fehler behandeln.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# Absoluter Pfad zu java-solution/, damit der Test von ueberall gestartet werden kann.
REPO_DIR=$(dirname "$SCRIPT_DIR")
# Elternordner des Java-Verzeichnisses; dort liegt das bereitgestellte dhmsg.
JAVA_BIN="${JAVA:-java}"
# Standard: java aus PATH verwenden; kann mit JAVA=/pfad/java ueberschrieben werden.

if [ -z "${JAVA:-}" ] && [ -x /usr/lib/jvm/java-21-openjdk-amd64/bin/java ]; then
    # Wenn kein JAVA explizit gesetzt ist und OpenJDK 21 existiert, verwenden wir Java 21.
    JAVA_BIN=/usr/lib/jvm/java-21-openjdk-amd64/bin/java
    # Grund: Die kompilierten Klassen brauchen mindestens Java 21, wenn mit Java 21 gebaut wurde.
fi

fail() {
    # Einheitliche Fehlerausgabe fuer fehlgeschlagene Tests.
    printf 'FAIL: %s\n' "$1" >&2
    # Fehler gehen nach stderr, damit stdout lesbar bleibt.
    exit 1
    # Beim ersten Fehler abbrechen, damit klar ist, welcher Test nicht stimmt.
}

pass() {
    # Einheitliche Erfolgsausgabe fuer bestandene Tests.
    printf 'PASS: %s\n' "$1"
    # Der Name des bestandenen Tests wird sichtbar ausgegeben.
}

assert_eq() {
    # Hilfsfunktion: vergleicht erwarteten und tatsaechlichen Text.
    name=$1
    # Name des Tests fuer die PASS/FAIL-Ausgabe.
    expected=$2
    # Erwarteter Wert.
    actual=$3
    # Tatsaechlicher Wert.
    if [ "$expected" != "$actual" ]; then
        # Wenn die Werte verschieden sind, wird die Abweichung ausgegeben.
        printf 'Expected:\n%s\nActual:\n%s\n' "$expected" "$actual" >&2
        # Erwartung und Ergebnis helfen beim Debuggen.
        fail "$name"
        # Danach wird der Test mit Fehler beendet.
    fi
    pass "$name"
    # Wenn beide Werte gleich sind, ist dieser Test bestanden.
}

cd "$SCRIPT_DIR"
# Alle folgenden relativen Pfade beziehen sich auf java-solution/.
./build.sh >/dev/null
# Vor jedem Testlauf neu kompilieren; Ausgabe unterdruecken, damit nur Testergebnisse sichtbar sind.

DH_OUT=$("$JAVA_BIN" -cp out itsicherheit.DhParam)
# dhparam ohne Argumente starten; es soll selbst m, g, priv und pub erzeugen.
printf '%s\n' "$DH_OUT" | grep -Eq '^m: [0-9a-f]+$' || fail 'dhparam prints m as hex'
# Prueft: m wird als Hex-Zahl im Format "m: <hex>" ausgegeben.
printf '%s\n' "$DH_OUT" | grep -Eq '^g: [0-9a-f]+$' || fail 'dhparam prints g as hex'
# Prueft: g wird als Hex-Zahl im Format "g: <hex>" ausgegeben.
printf '%s\n' "$DH_OUT" | grep -Eq '^priv: [0-9a-f]+$' || fail 'dhparam prints priv as hex'
# Prueft: priv wird als Hex-Zahl ausgegeben.
printf '%s\n' "$DH_OUT" | grep -Eq '^pub: [0-9a-f]+$' || fail 'dhparam prints pub as hex'
# Prueft: pub wird als Hex-Zahl ausgegeben.
M_HEX=$(printf '%s\n' "$DH_OUT" | awk '/^m:/ {print $2}')
# Extrahiert den Modulwert m aus der dhparam-Ausgabe.
G_HEX=$(printf '%s\n' "$DH_OUT" | awk '/^g:/ {print $2}')
# Extrahiert den Generator g aus der dhparam-Ausgabe.
M_DEC=$(printf '%d' "0x$M_HEX")
# Wandelt m von Hex nach Dezimal um, damit Bereichsvergleiche moeglich sind.
G_DEC=$(printf '%d' "0x$G_HEX")
# Wandelt g von Hex nach Dezimal um.
[ "$M_DEC" -ge 512 ] && [ "$M_DEC" -le 1023 ] || fail 'dhparam random m is in [2^9, 2^10-1]'
# Prueft Aufgabenanforderung: m liegt ohne Argumente zwischen 2^9 und 2^10-1.
[ "$G_DEC" -ge 2 ] && [ "$G_DEC" -lt "$M_DEC" ] || fail 'dhparam random g is in [2, m-1]'
# Prueft: g liegt im gueltigen Bereich Z_m ohne 0 und 1.
pass 'dhparam no-argument format and random ranges'
# Diese Gruppe ist bestanden: Format und Zufallsbereiche stimmen.

FIXED_OUT=$("$JAVA_BIN" -cp out itsicherheit.DhParam 11 5)
# dhparam mit festem m=0x11 und g=0x5 starten.
assert_eq 'dhparam keeps provided m' 'm: 11' "$(printf '%s\n' "$FIXED_OUT" | sed -n '1p')"
# Prueft: wenn m uebergeben wird, bleibt m genau erhalten.
assert_eq 'dhparam keeps provided g' 'g: 5' "$(printf '%s\n' "$FIXED_OUT" | sed -n '2p')"
# Prueft: wenn g uebergeben wird, bleibt g genau erhalten.
printf '%s\n' "$FIXED_OUT" | grep -Eq '^priv: [0-9a-f]+$' || fail 'dhparam fixed prints priv'
# Prueft: auch mit festen Parametern wird ein privater Schluessel erzeugt.
printf '%s\n' "$FIXED_OUT" | grep -Eq '^pub: [0-9a-f]+$' || fail 'dhparam fixed prints pub'
# Prueft: auch mit festen Parametern wird ein oeffentlicher Schluessel erzeugt.
pass 'dhparam with explicit m and g'
# Diese Gruppe ist bestanden: explizite Parameter funktionieren.

if "$JAVA_BIN" -cp out itsicherheit.DhParam 11 >/tmp/dhparam-one-arg.out 2>/tmp/dhparam-one-arg.err; then
    # dhparam darf nicht mit genau einem Argument erfolgreich sein.
    fail 'dhparam rejects exactly one argument'
    # Wenn es doch erfolgreich war, ist die Argumentpruefung falsch.
fi
grep -q 'Usage: dhparam' /tmp/dhparam-one-arg.err || fail 'dhparam one-argument usage message'
# Prueft: bei falscher Argumentzahl wird eine Usage-Meldung ausgegeben.
pass 'dhparam rejects incomplete arguments'
# Diese Gruppe ist bestanden: unvollstaendige Argumente werden abgelehnt.

if "$JAVA_BIN" -cp out itsicherheit.DhParam 11 1 >/tmp/dhparam-bad-g.out 2>/tmp/dhparam-bad-g.err; then
    # Generator 1 ist ungueltig, weil g im Bereich [2, m-1] liegen muss.
    fail 'dhparam rejects invalid g'
    # Wenn der Aufruf erfolgreich war, fehlt die Generatorpruefung.
fi
grep -q 'Generator g muss' /tmp/dhparam-bad-g.err || fail 'dhparam invalid-g error message'
# Prueft: die Fehlermeldung nennt den ungueltigen Generator.
pass 'dhparam rejects invalid generator'
# Diese Gruppe ist bestanden: ungueltiges g wird abgelehnt.

DIRECT_INPUT='MyPubkey: 7
Qnuux Fxaum+'
# Kuenstliche dhmsg-aehnliche Eingabe ohne Leerzeile: Header plus Chiffrat.
DIRECT_OUT=$(printf '%s\n' "$DIRECT_INPUT" | "$JAVA_BIN" -cp out itsicherheit.Decrypt 11 5 6)
# decrypt liest MyPubkey=7 und entschluesselt mit priv=6.
assert_eq 'decrypt known Vigenere/DH text' 'Hello World!' "$DIRECT_OUT"
# Prueft eine bekannte DH/Vigenere-Kombination: Ergebnis muss Hello World! sein.

SEP_INPUT='MyPubkey: 7

Qnuux Fxaum+'
# dhmsg gibt zwischen MyPubkey und Chiffrat eine Leerzeile aus; das wird hier simuliert.
SEP_OUT=$(printf '%s\n' "$SEP_INPUT" | "$JAVA_BIN" -cp out itsicherheit.Decrypt 11 5 6)
# decrypt muss diese Separator-Leerzeile ignorieren.
assert_eq 'decrypt dhmsg separator blank line' 'Hello World!' "$SEP_OUT"
# Prueft: keine zusaetzliche Leerzeile vor dem Klartext.

if printf 'bad\nCipher\n' | "$JAVA_BIN" -cp out itsicherheit.Decrypt 11 5 6 >/tmp/decrypt-bad.out 2>/tmp/decrypt-bad.err; then
    # decrypt darf Eingaben ohne "MyPubkey:" nicht akzeptieren.
    fail 'decrypt rejects missing MyPubkey header'
    # Wenn der Aufruf erfolgreich war, waere die Eingabevalidierung fehlerhaft.
fi
grep -q 'MyPubkey' /tmp/decrypt-bad.err || fail 'decrypt missing-header error message'
# Prueft: die Fehlermeldung erklaert, dass MyPubkey fehlt.
pass 'decrypt validates MyPubkey header'
# Diese Gruppe ist bestanden: decrypt validiert das Eingabeformat.

ROUND_TEXT='Abc XYZ, Zebra-42! Satzzeichen bleiben?'
# Testtext mit Gross-/Kleinschreibung, Leerzeichen, Zahlen, Satzzeichen und Ausrufezeichen.
ROUND_PARAMS=$("$JAVA_BIN" -cp out itsicherheit.DhParam 11 5)
# Neues Schluesselpaar fuer m=11, g=5 erzeugen.
ROUND_PRIV=$(printf '%s\n' "$ROUND_PARAMS" | awk '/^priv:/ {print $2}')
# Passenden privaten Schluessel extrahieren.
ROUND_PUB=$(printf '%s\n' "$ROUND_PARAMS" | awk '/^pub:/ {print $2}')
# Passenden oeffentlichen Schluessel extrahieren; diesen bekommt dhmsg.
ROUND_OUT=$(printf '%s\n' "$ROUND_TEXT" | "$REPO_DIR/dhmsg" 11 5 "$ROUND_PUB" | "$JAVA_BIN" -cp out itsicherheit.Decrypt 11 5 "$ROUND_PRIV")
# Echter Roundtrip: Klartext -> dhmsg -> decrypt.
assert_eq 'dhmsg roundtrip preserves letters, spaces, punctuation rules' "$ROUND_TEXT" "$ROUND_OUT"
# Prueft: Am Ende kommt derselbe Klartext heraus.

PDF_M=e4eea0d7a7430ca16823
# Modul aus dem PDF-Beispiel.
PDF_G=c1b0f4f1b8d891413ece
# Generator aus dem PDF-Beispiel.
PDF_TEXT='Hello World!'
# Klartext fuer den PDF-Parametertest.
PDF_PARAMS=$("$JAVA_BIN" -cp out itsicherheit.DhParam "$PDF_M" "$PDF_G")
# Java erzeugt ein Schluesselpaar zu den PDF-Parametern.
PDF_PRIV=$(printf '%s\n' "$PDF_PARAMS" | awk '/^priv:/ {print $2}')
# Privaten Schluessel extrahieren.
PDF_PUB=$(printf '%s\n' "$PDF_PARAMS" | awk '/^pub:/ {print $2}')
# Oeffentlichen Schluessel extrahieren.
PDF_OUT=$(printf '%s\n' "$PDF_TEXT" | "$REPO_DIR/dhmsg" "$PDF_M" "$PDF_G" "$PDF_PUB" | "$JAVA_BIN" -cp out itsicherheit.Decrypt "$PDF_M" "$PDF_G" "$PDF_PRIV")
# Echter Roundtrip mit den grossen Parametern aus der Aufgabenstellung.
assert_eq 'dhmsg roundtrip with PDF example m/g' "$PDF_TEXT" "$PDF_OUT"
# Prueft: Die Loesung funktioniert nicht nur mit kleinen Testzahlen.

rm -f /tmp/dh_session_11.tmp
# Alten Wrapper-Cache fuer m=11 entfernen, damit der Test deterministisch startet.
WRAP_TEXT='Wrapper Test!'
# Klartext fuer den Wrapper-Test.
WRAP_FIRST=$(./run-java.sh 11 5 7 2>&1)
# Erster Wrapper-Aufruf erzeugt und cached ein eigenes Schluesselpaar.
WRAP_PUB=$(printf '%s\n' "$WRAP_FIRST" | awk -F': ' '/Mein Public Key/ {print $2}')
# Den vom Wrapper ausgegebenen eigenen Public Key herauslesen.
[ -n "$WRAP_PUB" ] || fail 'wrapper prints own public key'
# Prueft: Der Wrapper hat wirklich einen Public Key ausgegeben.
WRAP_OUT=$(printf '%s\n' "$WRAP_TEXT" | "$REPO_DIR/dhmsg" 11 5 "$WRAP_PUB" | ./run-java.sh 11 5 7 --decrypt 2>/tmp/run-wrapper.err)
# dhmsg verschluesselt fuer WRAP_PUB; der zweite Wrapper-Aufruf nutzt den gecachten passenden Private Key.
assert_eq 'wrapper run-java.sh complete dhmsg decrypt flow' "$WRAP_TEXT" "$WRAP_OUT"
# Prueft: Der komplette Kolloquiumsablauf ueber den Wrapper funktioniert.
rm -f /tmp/dh_session_11.tmp
# Test-Cache wieder entfernen, damit spaetere manuelle Tests sauber starten.

printf 'All requirement tests passed.\n'
# Abschlussmeldung: Alle Anforderungen wurden erfolgreich getestet.
