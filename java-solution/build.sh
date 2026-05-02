#!/bin/sh
# Dieses Skript kompiliert die Java-Quellen fuer Linux/WSL.
set -eu
# -e: bei einem Fehler sofort abbrechen; -u: unbekannte Variablen als Fehler behandeln.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# Absoluter Pfad zu diesem Skript; dadurch funktioniert der Build aus jedem Arbeitsverzeichnis.
SRC_DIR="$SCRIPT_DIR/src/main/java"
# Hier liegen die Java-Quelldateien.
OUT_DIR="$SCRIPT_DIR/out"
# Hier landen die kompilierten .class-Dateien.
JAVAC_BIN="${JAVAC:-javac}"
# Standard: javac aus PATH verwenden; kann mit JAVAC=/pfad/javac ueberschrieben werden.

if [ -z "${JAVAC:-}" ] && [ -x /usr/lib/jvm/java-21-openjdk-amd64/bin/javac ]; then
    # Wenn kein JAVAC explizit gesetzt ist und OpenJDK 21 existiert, wird Java 21 bevorzugt.
    JAVAC_BIN=/usr/lib/jvm/java-21-openjdk-amd64/bin/javac
    # Das verhindert Probleme, wenn WSL noch Java 11 als Standard-Java hat.
fi

mkdir -p "$OUT_DIR"
# Ausgabeverzeichnis anlegen, falls es noch nicht existiert.
"$JAVAC_BIN" -encoding UTF-8 -d "$OUT_DIR" "$SRC_DIR"/itsicherheit/*.java
# Alle Java-Dateien im Paket itsicherheit kompilieren und in out/ ablegen.

echo "Fertig. Startbeispiele:"
# Kurze Erfolgsmeldung mit Beispielbefehlen.
echo "  java -cp \"$OUT_DIR\" itsicherheit.DhParam <m> <g>"
# Beispiel: DH-Parameter und Schluessel erzeugen.
echo "  cat cipher.txt | java -cp \"$OUT_DIR\" itsicherheit.Decrypt <m> <g> <priv>"
# Beispiel: eine dhmsg-Ausgabe aus einer Datei entschluesseln.
