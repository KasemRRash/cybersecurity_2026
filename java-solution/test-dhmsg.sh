#!/bin/sh
# Kleiner End-to-End-Test: Java erzeugt Schluessel, dhmsg verschluesselt, Java entschluesselt.
set -eu
# Bei Fehlern sofort abbrechen und undefinierte Variablen verbieten.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# Absoluter Pfad zu java-solution/.
REPO_DIR=$(dirname "$SCRIPT_DIR")
# Elternordner; dort liegt das bereitgestellte Programm dhmsg.
JAVA_BIN="${JAVA:-java}"
# Standard-Java; kann bei Bedarf durch die Umgebungsvariable JAVA ersetzt werden.

if [ -z "${JAVA:-}" ] && [ -x /usr/lib/jvm/java-21-openjdk-amd64/bin/java ]; then
    # OpenJDK 21 bevorzugen, wenn es auf WSL installiert ist.
    JAVA_BIN=/usr/lib/jvm/java-21-openjdk-amd64/bin/java
    # So laeuft der Test auch, wenn das globale java noch Version 11 ist.
fi

M="${1:-11}"
# Erstes Argument: Modul m; Standard ist 11 fuer einen kleinen, nachvollziehbaren Test.
G="${2:-5}"
# Zweites Argument: Generator g; Standard ist 5.
TEXT="${3:-Hello World!}"
# Drittes Argument: Testnachricht; Standard ist Hello World!

PARAMS=$("$JAVA_BIN" -cp "$SCRIPT_DIR/out" itsicherheit.DhParam "$M" "$G")
# Java-DhParam erzeugt priv/pub passend zu m und g.
PRIV=$(printf "%s\n" "$PARAMS" | awk '/^priv:/ {print $2}')
# Privaten Schluessel aus der Ausgabe herauslesen.
PUB=$(printf "%s\n" "$PARAMS" | awk '/^pub:/ {print $2}')
# Oeffentlichen Schluessel aus der Ausgabe herauslesen; diesen bekommt dhmsg.

printf 'm=%s g=%s priv=%s pub=%s\n' "$M" "$G" "$PRIV" "$PUB" >&2
# Testparameter auf stderr anzeigen; stdout bleibt fuer den entschluesselten Klartext.
printf '%s\n' "$TEXT" | "$REPO_DIR/dhmsg" "$M" "$G" "$PUB" | "$JAVA_BIN" -cp "$SCRIPT_DIR/out" itsicherheit.Decrypt "$M" "$G" "$PRIV"
# Ablauf: Klartext -> dhmsg verschluesselt fuer PUB -> Decrypt entschluesselt mit PRIV.
