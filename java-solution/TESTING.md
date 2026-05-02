# Testanleitung fuer die Java-Loesung

Diese Anleitung zeigt den korrekten Ablauf fuer `dhparam`, `decrypt`, `run-java.sh`
und `dhmsg` unter Linux/WSL.

## 1. Vorbereitung

In WSL:

```sh
cd /mnt/c/Users/zuela/Downloads/ITSicherheit_A1/java-solution
chmod +x build.sh run-java.sh test-dhmsg.sh test-requirements.sh
./build.sh
```

Erwartung:

```text
Fertig.
```

Falls dein normales `java` noch Java 11 ist, ist das kein Problem. Die Skripte verwenden
automatisch Java 21 unter `/usr/lib/jvm/java-21-openjdk-amd64`, falls vorhanden.

## 2. Wichtiges Prinzip

`dhmsg` muss immer den Public Key bekommen, der direkt vorher von deinem Programm
ausgegeben wurde.

Falsch:

```sh
./run-java.sh 5 3 4
echo 'Text' | /usr/local/bin/dhmsg 5 3 4 | ./run-java.sh 5 3 4 --decrypt
```

Das ist falsch, wenn `run-java.sh` vorher zum Beispiel diesen Public Key ausgegeben hat:

```text
Mein Public Key (fuer dhmsg): 2
```

Dann muss `dhmsg` auch `2` bekommen:

```sh
echo 'Text' | /usr/local/bin/dhmsg 5 3 2 | ./run-java.sh 5 3 4 --decrypt
```

Der dritte Parameter von `run-java.sh` ist der Public Key der anderen Seite, also zum Beispiel
vom Professor. Fuer `dhmsg` brauchst du aber deinen eigenen Public Key aus der Ausgabe von
`run-java.sh`.

## 3. Korrekter manueller Ablauf

Beispiel mit den Parametern aus der Aufgabenstellung:

```sh
M=e4eea0d7a7430ca16823
G=c1b0f4f1b8d891413ece
PROF_PUB=71d00f8559aa5c90c420
```

Schritt 1: eigenes Schluesselpaar erzeugen.

```sh
./run-java.sh "$M" "$G" "$PROF_PUB"
```

Beispielausgabe:

```text
=== Eigene DH-Parameter ===
m: e4eea0d7a7430ca16823
g: c1b0f4f1b8d891413ece
priv: 9d5d263e419c92a7d079
pub: 66839d147fe396251592

Mein Public Key (fuer dhmsg): 66839d147fe396251592
```

Schritt 2: genau diesen Public Key bei `dhmsg` einsetzen.

```sh
echo 'Text' | /usr/local/bin/dhmsg "$M" "$G" 66839d147fe396251592 | ./run-java.sh "$M" "$G" "$PROF_PUB" --decrypt
```

Erwartung:

```text
Text
```

Nach erfolgreichem `--decrypt` wird der gecachte Private Key geloescht. Fuer die naechste
Nachricht muss daher zuerst wieder `./run-java.sh "$M" "$G" "$PROF_PUB"` ausgefuehrt werden.

## 4. Was ohne `decrypt` sichtbar ist

Nur `dhmsg`:

```sh
echo 'Text' | /usr/local/bin/dhmsg "$M" "$G" 66839d147fe396251592
```

Erwartung:

```text
MyPubkey: <public-key-von-dhmsg>

<verschluesselter Text>
```

Hier kommt also nicht `Text` heraus, sondern das Chiffrat.

Mit `decrypt`:

```sh
echo 'Text' | /usr/local/bin/dhmsg "$M" "$G" 66839d147fe396251592 | ./run-java.sh "$M" "$G" "$PROF_PUB" --decrypt
```

Erwartung:

```text
Text
```

## 5. Automatischer Schnelltest

```sh
./test-dhmsg.sh
```

Dieser Test macht automatisch:

1. `dhparam` erzeugt `priv` und `pub`.
2. `dhmsg` verschluesselt `Hello World!` fuer diesen `pub`.
3. `decrypt` entschluesselt mit dem passenden `priv`.

Erwartung:

```text
m=11 g=5 priv=<zufaellig> pub=<passend>
Hello World!
```

`priv` und `pub` duerfen bei jedem Lauf anders sein. Das ist richtig, weil der private
Schluessel zufaellig erzeugt wird.

## 6. Vollstaendiger Anforderungstest

```sh
./test-requirements.sh
```

Dieser Test prueft:

- `dhparam` kompiliert und startet.
- `dhparam` gibt `m`, `g`, `priv`, `pub` als Hex-Zahlen aus.
- Ohne Argumente liegt `m` im Bereich `2^9` bis `2^10 - 1`.
- `g` liegt im gueltigen Bereich.
- Mit Argumenten bleiben `m` und `g` erhalten.
- Ein einzelnes Argument wird korrekt abgelehnt.
- Ein ungueltiger Generator wird korrekt abgelehnt.
- `decrypt` akzeptiert nur Eingaben mit `MyPubkey:`.
- Die Leerzeile von `dhmsg` nach `MyPubkey:` wird ignoriert.
- Vigenere-Entschluesselung funktioniert.
- Gross-/Kleinschreibung bleibt erhalten.
- Leerzeichen und normale Satzzeichen bleiben erhalten.
- `!` wird ueber `+` korrekt zurueckgewandelt.
- Ein Roundtrip mit den PDF-Beispielparametern funktioniert.
- Der komplette Wrapper-Ablauf mit `run-java.sh` funktioniert.

Erwartung:

```text
PASS: dhparam no-argument format and random ranges
PASS: dhparam keeps provided m
PASS: dhparam keeps provided g
PASS: dhparam with explicit m and g
PASS: dhparam rejects incomplete arguments
PASS: dhparam rejects invalid generator
PASS: decrypt known Vigenere/DH text
PASS: decrypt dhmsg separator blank line
PASS: decrypt validates MyPubkey header
PASS: dhmsg roundtrip preserves letters, spaces, punctuation rules
PASS: dhmsg roundtrip with PDF example m/g
PASS: wrapper run-java.sh complete dhmsg decrypt flow
All requirement tests passed.
```

## 7. Typische Fehlerfaelle

### Fehlerfall A: Alter Public Key wird wiederverwendet

```sh
./run-java.sh 5 3 4
```

Angenommen die Ausgabe ist:

```text
Mein Public Key (fuer dhmsg): 2
```

Dann ist das falsch:

```sh
echo 'Text' | /usr/local/bin/dhmsg 5 3 4 | ./run-java.sh 5 3 4 --decrypt
```

Warum? Das Chiffrat wurde fuer Public Key `4` erzeugt, aber dein aktueller Private Key passt
zu Public Key `2`.

Moegliche falsche Ausgabe:

```text
Vgzv
```

Richtig:

```sh
echo 'Text' | /usr/local/bin/dhmsg 5 3 2 | ./run-java.sh 5 3 4 --decrypt
```

Erwartung:

```text
Text
```

### Fehlerfall B: `echo` wird falsch verwendet

Falsch:

```sh
echo "Text" ./run-java.sh 5 3 4
```

Das startet `run-java.sh` nicht. Es gibt nur Text auf der Konsole aus:

```text
Text ./run-java.sh 5 3 4
```

Richtig ist eine Pipe:

```sh
echo 'Text' | /usr/local/bin/dhmsg 5 3 <dein-public-key> | ./run-java.sh 5 3 4 --decrypt
```

### Fehlerfall C: Nach erfolgreichem `--decrypt` ist der Cache weg

Nach:

```sh
echo 'Text' | /usr/local/bin/dhmsg "$M" "$G" "$PUB" | ./run-java.sh "$M" "$G" "$PROF_PUB" --decrypt
```

wird der gespeicherte Private Key geloescht.

Wenn du danach nochmal mit demselben alten `$PUB` verschluesselst, kann es falsch werden,
weil `run-java.sh` ein neues Schluesselpaar erzeugt.

Richtig: fuer jede neue Runde zuerst wieder:

```sh
./run-java.sh "$M" "$G" "$PROF_PUB"
```

und dann den neu ausgegebenen Public Key bei `dhmsg` einsetzen.

## 8. Kolloquiumsablauf

Wenn du im Kolloquium `m`, `g`, Professor-Public-Key und ein Chiffrat bekommst:

1. Eigenen Public Key erzeugen:

```sh
./run-java.sh "$M" "$G" "$PROF_PUB"
```

2. Deinen ausgegebenen Public Key mitteilen.

3. Chiffrat empfangen.

4. Chiffrat entschluesseln:

```sh
cat cipher.txt | ./run-java.sh "$M" "$G" "$PROF_PUB" --decrypt
```

Erwartung: Es kommt der Klartext heraus.

## 9. Was du erklaeren koennen solltest

- `priv` ist geheim und bleibt lokal.
- `pub = g^priv mod m` ist oeffentlich.
- `dhmsg` erzeugt selbst ebenfalls einen Public Key und schreibt ihn in `MyPubkey:`.
- Beide Seiten berechnen dasselbe gemeinsame Geheimnis:

```text
shared = peer_pub^own_priv mod m
```

- Aus `shared` wird der Vigenere-Schluessel gebildet:
  Zahl in Basis 26, Ziffer 0 bis 25 wird zu `A` bis `Z`.
- Vigenere verschluesselt nur Buchstaben.
- Gross-/Kleinschreibung bleibt erhalten.
- `!` wird von `dhmsg` als `+` kodiert und beim Entschluesseln zurueckgewandelt.
- Andere Zeichen bleiben unveraendert.
