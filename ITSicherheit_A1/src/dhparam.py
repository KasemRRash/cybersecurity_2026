#!/usr/bin/env python3
"""
dhparam - Diffie-Hellman Parameter- und Schlüsselerzeugung
Aufruf: dhparam [<m> <g>]
  Ohne Parameter: m wird zufällig im Bereich [2^9, 2^10 - 1] gewählt,
                  g wird zufällig aus Z_m gewählt.
  Mit Parametern: m und g werden als Hex-Zahlen übergeben.
Ausgabe (hex):
  m: <Modul>
  g: <Generator>
  priv: <privater Schlüssel>
  pub:  <öffentlicher Schlüssel>
"""

import sys
import secrets


def hex_to_int(s: str) -> int:
    return int(s, 16)


def int_to_hex(n: int) -> str:
    return format(n, "x")


def random_in_range(lo: int, hi: int) -> int:
    """Gibt eine gleichverteilte Zufallszahl aus [lo, hi] zurück."""
    span = hi - lo + 1
    return lo + secrets.randbelow(span)


def generate_private_key(m: int) -> int:
    """Privater Schlüssel: zufällig aus [2, m-2]."""
    return random_in_range(2, m - 2)


def main() -> None:
    if len(sys.argv) == 1:
        # Kein Modul / Generator vorgegeben → selbst wählen
        # Modul: zufällig im Bereich [2^9, 2^10 - 1]
        m = random_in_range(2**9, 2**10 - 1)
        # Generator: zufällig aus [2, m-1]
        g = random_in_range(2, m - 1)
    elif len(sys.argv) == 3:
        m = hex_to_int(sys.argv[1])
        g = hex_to_int(sys.argv[2])
        # Sanity-Check laut Aufgabe nur bei selbst-generiertem Modul vorgeschrieben,
        # aber wir prüfen trotzdem ob m im sinnvollen Bereich liegt.
        if not (2 <= g < m):
            print(
                f"Fehler: Generator g muss im Bereich [2, m-1] liegen.", file=sys.stderr
            )
            sys.exit(1)
    else:
        print("Usage: dhparam [<m> <g>]", file=sys.stderr)
        sys.exit(1)

    priv = generate_private_key(m)
    pub = pow(g, priv, m)   # pub = g^priv mod m  (schnelle modulare Exponentiation)

    print(f"m: {int_to_hex(m)}")
    print(f"g: {int_to_hex(g)}")
    print(f"priv: {int_to_hex(priv)}")
    print(f"pub: {int_to_hex(pub)}")


if __name__ == "__main__":
    main()
