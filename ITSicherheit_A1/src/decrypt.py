#!/usr/bin/env python3
"""
decrypt - Entschlüsselt eine mit dhmsg (Vigenere + Diffie-Hellman) verschlüsselte Nachricht.

Aufruf:
  dhmsg <m> <g> <pub> | decrypt <m> <g> <priv>

Eingabe (stdin):
  Zeile 1: "MyPubkey: <hex>"   ← öffentlicher Schlüssel des Senders (aus dhmsg-Ausgabe)
  Rest:    Chiffrat

Verfahren:
  1. Gemeinsames Geheimnis: shared = sender_pub^priv mod m  (Diffie-Hellman)
  2. Vigenere-Schlüssel aus shared:  Darstellung zur Basis 26, Ziffern → Buchstaben (0=A)
  3. Vigenere-Entschlüsselung:
       - Nur Klein-/Großbuchstaben werden entschlüsselt, Groß-/Kleinschreibung bleibt erhalten.
       - '+' wird zu '!' zurückgewandelt (dhmsg kodiert '!' → '+').
       - Alle anderen Zeichen bleiben unverändert.
"""

import sys


# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------

def hex_to_int(s: str) -> int:
    return int(s, 16)


def int_to_hex(n: int) -> str:
    return format(n, "x")


def secret_to_vigenere_key(secret: int) -> str:
    """
    Wandelt das gemeinsame DH-Geheimnis in einen Vigenere-Schlüssel um.

    Verfahren (laut Aufgabe):
      - Darstellung der Zahl zur Basis 26.
      - Jede Ziffer d kodiert den Buchstaben chr('A' + d).
    Beispiel: 6572 (dez)  = 9·26² + 18·26 + 10  → Ziffern [9,18,10] → "JSK"
              (Aufgabe: 6572₁₀ = 9ik₂₆ → JSU  –  dort wird i=8, k=10 verwendet;
               das entspricht der normalen Basis-26-Darstellung.)
    Sonderfall: secret == 0  →  "A"
    """
    if secret == 0:
        return "A"

    digits: list[int] = []
    n = secret
    while n > 0:
        digits.append(n % 26)
        n //= 26
    digits.reverse()                          # höchstwertige Stelle zuerst
    return "".join(chr(ord("A") + d) for d in digits)


def decrypt_vigenere(ciphertext: str, key: str) -> str:
    """
    Vigenere-Entschlüsselung.

    Regeln laut dhmsg:
      - Nur Buchstaben (a-z, A-Z) wurden verschlüsselt; Groß-/Kleinschreibung bleibt.
      - '!' wurde zu '+' kodiert → '+' wird zu '!' zurückgewandelt.
      - Alle anderen Zeichen bleiben unverändert.
    """
    result: list[str] = []
    key_index = 0

    for c in ciphertext:
        if c == "+":
            result.append("!")
        elif c.isalpha():
            shift = ord(key[key_index % len(key)]) - ord("A")
            base = ord("A") if c.isupper() else ord("a")
            decrypted = (ord(c) - base - shift) % 26
            result.append(chr(base + decrypted))
            key_index += 1
        else:
            result.append(c)

    return "".join(result)


# ---------------------------------------------------------------------------
# Hauptprogramm
# ---------------------------------------------------------------------------

def main() -> None:
    if len(sys.argv) != 4:
        print("Usage: decrypt <m> <g> <priv>", file=sys.stderr)
        sys.exit(1)

    m    = hex_to_int(sys.argv[1])
    # g wird für die reine Entschlüsselung nicht benötigt, aber als Parameter
    # erwartet (symmetrisch zu dhmsg/dhparam).
    _g   = hex_to_int(sys.argv[2])   # noqa: F841
    priv = hex_to_int(sys.argv[3])

    data = sys.stdin.read()
    lines = data.splitlines()

    # --- Sender-Pubkey aus der ersten Zeile lesen ---
    if not lines or not lines[0].startswith("MyPubkey:"):
        print(
            "Fehler: Erste Zeile muss 'MyPubkey: <hex>' enthalten.",
            file=sys.stderr,
        )
        sys.exit(1)

    sender_pub_hex = lines[0].split(":", 1)[1].strip()
    sender_pub     = hex_to_int(sender_pub_hex)

    # Chiffrat: alles nach der ersten Zeile
    ciphertext = "\n".join(lines[1:])

    # --- Diffie-Hellman: gemeinsames Geheimnis berechnen ---
    shared_secret = pow(sender_pub, priv, m)   # sender_pub^priv mod m

    # --- Vigenere-Schlüssel ableiten ---
    key = secret_to_vigenere_key(shared_secret)

    # --- Entschlüsseln und ausgeben ---
    plaintext = decrypt_vigenere(ciphertext, key)
    print(plaintext)


if __name__ == "__main__":
    main()
