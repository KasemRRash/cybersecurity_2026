#!/bin/sh
# Wrapper fuer die Java-Klasse itsicherheit.Run.
set -eu
# -e bricht bei Fehlern ab; -u verhindert unbemerkte Tippfehler bei Variablen.

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    # run-java.sh braucht m, g, den Public Key der Gegenseite und optional --decrypt.
    echo "Usage: $0 <m> <g> <prof_pubkey> [--decrypt]" >&2
    # Fehlermeldung nach stderr, damit stdout fuer Klartext/Chiffrat frei bleibt.
    exit 1
    # Mit Fehlercode beenden, weil der Aufruf falsch war.
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# Absoluter Pfad zum Skript; damit finden wir out/ unabhaengig vom aktuellen Ordner.
JAVA_BIN="${JAVA:-java}"
# Standard: java aus PATH verwenden; kann mit JAVA=/pfad/java ueberschrieben werden.

if [ -z "${JAVA:-}" ] && [ -x /usr/lib/jvm/java-21-openjdk-amd64/bin/java ]; then
    # Wenn OpenJDK 21 installiert ist, verwenden wir es automatisch.
    JAVA_BIN=/usr/lib/jvm/java-21-openjdk-amd64/bin/java
    # Grund: In WSL war javac 21 vorhanden, aber java zeigte teilweise noch auf Java 11.
fi

exec "$JAVA_BIN" -cp "$SCRIPT_DIR/out" itsicherheit.Run "$@"
# Startet die Java-Hauptklasse Run mit allen Originalargumenten.
# exec ersetzt den Shell-Prozess durch Java; es bleibt kein unnoetiger Wrapper-Prozess.
