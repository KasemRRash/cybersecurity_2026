#!/bin/bash
# build.sh – Kompiliert/installiert die Quellen und erzeugt ausführbare Dateien in bin/
#
# Da die Programme in Python 3 geschrieben sind, ist kein Compilieren nötig.
# Dieses Skript kopiert die Quelldateien nach bin/ und setzt die Executable-Bits.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
BIN_DIR="$SCRIPT_DIR/bin"

echo "Erzeuge Verzeichnis bin/ ..."
mkdir -p "$BIN_DIR"

echo "Installiere dhparam ..."
cp "$SRC_DIR/dhparam.py" "$BIN_DIR/dhparam"
chmod +x "$BIN_DIR/dhparam"

echo "Installiere decrypt ..."
cp "$SRC_DIR/decrypt.py" "$BIN_DIR/decrypt"
chmod +x "$BIN_DIR/decrypt"

echo "Setze Rechte für run.sh ..."
chmod +x "$SCRIPT_DIR/run.sh"

echo ""
echo "Fertig. Ausführbare Dateien:"
ls -lh "$BIN_DIR/"
