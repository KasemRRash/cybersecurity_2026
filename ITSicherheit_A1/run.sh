#!/bin/bash
# run.sh – Wrapper für das Kolloquium (Diffie-Hellman + Vigenere)
#
# PROBLEM: DH ist ein Schlüsseltausch in zwei Schritten:
#   1. Erst eigenen Public Key erzeugen und dem Sender mitteilen
#   2. Dann das Chiffrat (das mit dem eigenen Public Key verschlüsselt wurde) entschlüsseln
#
# VERWENDUNG:
#
#   Schritt 1 – Schlüsselpaar erzeugen, Public Key ausgeben:
#     ./run.sh <m> <g> <prof_pub>
#
#   Schritt 2 – Chiffrat entschlüsseln (stdin = Ausgabe von dhmsg):
#     echo 'Chiffrat' | /usr/local/bin/dhmsg <m> <g> <mein_pub> | ./run.sh <m> <g> <prof_pub> --decrypt
#
# BEISPIEL (vollständiger Test-Ablauf):
#   M=e4eea0d7a7430ca16823
#   G=c1b0f4f1b8d891413ece
#   PROF_PUB=71d00f8559aa5c90c420
#
#   ./run.sh $M $G $PROF_PUB               # → gibt "Mein Public Key: abc" aus
#   # Notiere deinen Public Key (z.B. abc), dann:
#   echo 'Hello World!' | /usr/local/bin/dhmsg $M $G abc | ./run.sh $M $G $PROF_PUB --decrypt

set -euo pipefail

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <m> <g> <prof_pubkey> [--decrypt]" >&2
    exit 1
fi

M="$1"
G="$2"
PROF_PUB="$3"
MODE="${4:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
PRIV_TMP="/tmp/dh_session_${M}.tmp"

# ---------------------------------------------------------------------------
# Schlüsselpaar erzeugen (oder gecachtes laden)
# ---------------------------------------------------------------------------
if [ ! -f "$PRIV_TMP" ]; then
    PARAMS=$("$BIN_DIR/dhparam" "$M" "$G")
    MYPRIV=$(echo "$PARAMS" | awk '/^priv:/{print $2}')
    MYPUB=$(echo  "$PARAMS" | awk '/^pub:/{print $2}')
    printf '%s\n%s\n' "$MYPRIV" "$MYPUB" > "$PRIV_TMP"
    echo "=== Eigene DH-Parameter ===" >&2
    echo "$PARAMS" >&2
else
    MYPRIV=$(sed -n '1p' "$PRIV_TMP")
    MYPUB=$(sed -n  '2p' "$PRIV_TMP")
    echo "(Gecachtes Schlüsselpaar wird verwendet)" >&2
fi

echo >&2
echo "Mein Public Key (für dhmsg): $MYPUB"
echo >&2

# ---------------------------------------------------------------------------
# Entschlüsseln (nur wenn --decrypt übergeben wurde)
# ---------------------------------------------------------------------------
if [ "$MODE" = "--decrypt" ]; then
    "$BIN_DIR/decrypt" "$M" "$G" "$MYPRIV"
    rm -f "$PRIV_TMP"
else
    echo "Nächster Schritt:" >&2
    echo "  echo 'Text' | /usr/local/bin/dhmsg $M $G $MYPUB | ./run.sh $M $G $PROF_PUB --decrypt" >&2
fi
