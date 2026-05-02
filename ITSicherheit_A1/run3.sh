#!/bin/bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <m> <g> <pubkey>" >&2
    exit 1
fi

M="$1"
G="$2"
THEIR_PUB="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"

PARAMS=$("$BIN_DIR/dhparam" "$M" "$G")

PRIV=$(echo "$PARAMS" | awk '/^priv:/ {print $2}')
MYPUB=$(echo "$PARAMS" | awk '/^pub:/ {print $2}')

echo "Mein Public Key:" >&2
echo "$MYPUB" >&2

# Eingabe für decrypt künstlich bauen:
# 1. Zeile: MyPubkey: THEIR_PUB
# danach: Chiffrat von stdin
{
    echo "MyPubkey: $THEIR_PUB"
    cat
} | "$BIN_DIR/decrypt" "$M" "$G" "$PRIV"
