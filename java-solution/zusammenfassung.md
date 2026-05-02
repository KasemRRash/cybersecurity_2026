# Zusammenfassung fuer die muendliche Pruefung

## Ziel der Loesung

Die Java-Loesung setzt zwei Verfahren aus der Aufgabe praktisch um:

- Diffie-Hellman-Schluesselaustausch
- Vigenere-Entschluesselung

Das bereitgestellte Programm `dhmsg` verschluesselt eine Nachricht. Unsere Java-Programme
erzeugen die passenden DH-Schluessel und entschluesseln die Ausgabe von `dhmsg`.

## Wichtige Regel

`dhmsg` muss immer den Public Key bekommen, den unser Programm vorher ausgegeben hat.

Beispiel:

```text
Mein Public Key (fuer dhmsg): 66839d147fe396251592
```

Dann muss genau dieser Wert bei `dhmsg` eingesetzt werden:

```sh
echo 'Text' | /usr/local/bin/dhmsg "$M" "$G" 66839d147fe396251592
```

Wenn ein alter oder falscher Public Key verwendet wird, kommt beim Entschluesseln falscher Text
heraus, weil der Private Key nicht zum Chiffrat passt.

## Ablauf im Kolloquium

1. Du bekommst `m`, `g` und den Public Key der Gegenseite.

2. Du erzeugst deinen eigenen Public Key:

```sh
./run-java.sh "$M" "$G" "$PROF_PUB"
```

3. Du gibst den ausgegebenen Public Key weiter.

4. Die Gegenseite oder `dhmsg` erzeugt ein Chiffrat fuer genau diesen Public Key.

5. Du entschluesselst:

```sh
cat cipher.txt | ./run-java.sh "$M" "$G" "$PROF_PUB" --decrypt
```

6. Erwartung: Der Klartext wird ausgegeben.

## Was `DhParam` macht

Datei:

```text
src/main/java/itsicherheit/DhParam.java
```

Aufgabe:

- Erzeugt Diffie-Hellman-Parameter und ein Schluesselpaar.
- Aufruf ohne Argumente:

```sh
java -cp out itsicherheit.DhParam
```

- Aufruf mit festem Modul und Generator:

```sh
java -cp out itsicherheit.DhParam <m> <g>
```

Wichtige Schritte:

- `m` und `g` werden als Hex-Zahlen gelesen oder zufaellig erzeugt.
- `priv` wird zufaellig gewaehlt.
- `pub` wird berechnet mit:

```text
pub = g^priv mod m
```

Ausgabe:

```text
m: <hex>
g: <hex>
priv: <hex>
pub: <hex>
```

Pruefungsrelevanter Satz:

> Der private Schluessel bleibt geheim. Der oeffentliche Schluessel darf weitergegeben werden.

## Was `Decrypt` macht

Datei:

```text
src/main/java/itsicherheit/Decrypt.java
```

Aufgabe:

- Liest eine `dhmsg`-Ausgabe von stdin.
- Erwartet in der ersten Zeile:

```text
MyPubkey: <hex>
```

- Danach folgt das Chiffrat.

Wichtige Schritte:

1. `m`, `g`, `priv` werden als Argumente gelesen.
2. Der Public Key von `dhmsg` wird aus `MyPubkey:` gelesen.
3. Das gemeinsame Geheimnis wird berechnet:

```text
shared = sender_pub^priv mod m
```

4. Aus `shared` wird der Vigenere-Schluessel erzeugt.
5. Das Chiffrat wird mit Vigenere entschluesselt.

Pruefungsrelevanter Satz:

> Beide Seiten berechnen dasselbe gemeinsame Geheimnis, obwohl sie ihre privaten Schluessel nie austauschen.

## Was `Vigenere` macht

Datei:

```text
src/main/java/itsicherheit/Vigenere.java
```

Aufgabe:

- Wandelt das gemeinsame DH-Geheimnis in einen Vigenere-Schluessel um.
- Entschluesselt den Text.

Schluesselerzeugung:

- Die Zahl `shared` wird in Basis 26 umgerechnet.
- Jede Ziffer wird zu einem Buchstaben:

```text
0 -> A
1 -> B
...
25 -> Z
```

Entschluesselungsregeln:

- Nur Buchstaben werden veraendert.
- Grossbuchstaben bleiben gross.
- Kleinbuchstaben bleiben klein.
- Leerzeichen, Zahlen und normale Satzzeichen bleiben unveraendert.
- `+` wird wieder zu `!`, weil `dhmsg` Ausrufezeichen als Pluszeichen ausgibt.

## Was `Run` macht

Datei:

```text
src/main/java/itsicherheit/Run.java
```

Aufgabe:

- Ist der Java-Wrapper fuer den Kolloquiumsablauf.
- Erzeugt zuerst ein eigenes DH-Schluesselpaar.
- Speichert `priv` und `pub` temporaer in `/tmp/dh_session_<m>.tmp`.
- Gibt den eigenen Public Key aus.
- Mit `--decrypt` liest er das Chiffrat von stdin und entschluesselt es.

Warum Cache?

Der Ablauf hat zwei Phasen:

1. Public Key erzeugen und weitergeben.
2. Spaeter Chiffrat entschluesseln.

Dafuer muss derselbe Private Key noch vorhanden sein. Deshalb wird er zwischengespeichert.

Nach erfolgreichem `--decrypt` wird der Cache geloescht, damit die naechste Runde ein neues
Schluesselpaar erzeugt.

## Was die Skripte machen

### `build.sh`

- Kompiliert die Java-Dateien unter Linux/WSL.
- Legt die `.class`-Dateien in `out/` ab.
- Nutzt automatisch OpenJDK 21, falls vorhanden.

Start:

```sh
./build.sh
```

### `run-java.sh`

- Startet die Java-Klasse `itsicherheit.Run`.
- Nimmt dieselben Argumente wie der Wrapper:

```sh
./run-java.sh <m> <g> <prof_pubkey> [--decrypt]
```

Ohne `--decrypt`:

- Schluesselpaar erzeugen oder Cache laden.
- Eigenen Public Key anzeigen.

Mit `--decrypt`:

- Chiffrat aus stdin lesen.
- Mit gecachtem Private Key entschluesseln.

### `test-dhmsg.sh`

- Kleiner End-to-End-Test.
- Erzeugt ein Schluesselpaar.
- Gibt den Public Key an `dhmsg`.
- Entschluesselt mit dem passenden Private Key.

Start:

```sh
./test-dhmsg.sh
```

Erwartung:

```text
Hello World!
```

### `test-requirements.sh`

- Vollstaendiger Test gegen die wichtigsten Anforderungen.
- Prueft Format, Fehlerfaelle, echte `dhmsg`-Roundtrips und den Wrapper.

Start:

```sh
./test-requirements.sh
```

Erwartung:

```text
All requirement tests passed.
```

## Was getestet wird

Der Volltest prueft:

- Build funktioniert.
- `dhparam` gibt vier Hex-Zahlen aus.
- Zufallswerte liegen im erwarteten Bereich.
- Explizite Parameter werden korrekt uebernommen.
- Falsche Argumente werden abgelehnt.
- `decrypt` verlangt `MyPubkey:`.
- Die Leerzeile von `dhmsg` nach `MyPubkey:` wird ignoriert.
- Bekannte DH/Vigenere-Entschluesselung ergibt `Hello World!`.
- Echte Verschluesselung mit `dhmsg` und Entschluesselung mit Java funktioniert.
- Die PDF-Beispielparameter funktionieren.
- Der komplette Wrapper-Ablauf funktioniert.

## Typische Fehlererklaerung

Wenn nicht der urspruengliche Text zurueckkommt, ist fast immer der Public Key falsch.

Beispiel:

```text
Mein Public Key (fuer dhmsg): 2
```

Dann ist falsch:

```sh
echo 'Text' | dhmsg 5 3 4 | ./run-java.sh 5 3 4 --decrypt
```

Richtig:

```sh
echo 'Text' | dhmsg 5 3 2 | ./run-java.sh 5 3 4 --decrypt
```

Der dritte Parameter von `run-java.sh` ist nicht automatisch dein Public Key. Dein Public Key ist
der Wert, den `run-java.sh` ausgibt.

## Kurze muendliche Erklaerung

Eine moegliche Antwort in der Pruefung:

> Mein Programm erzeugt zuerst einen privaten Diffie-Hellman-Schluessel und berechnet daraus den
> oeffentlichen Schluessel mit `g^priv mod m`. Diesen Public Key gebe ich an `dhmsg`. `dhmsg`
> verschluesselt die Nachricht fuer meinen Public Key und gibt seinen eigenen Public Key in der
> Zeile `MyPubkey:` aus. Beim Entschluesseln liest mein Programm diesen Public Key, berechnet mit
> meinem Private Key dasselbe gemeinsame Geheimnis und leitet daraus den Vigenere-Schluessel ab.
> Danach wird die Vigenere-Verschluesselung rueckgaengig gemacht. Deshalb kommt am Ende wieder
> der urspruengliche Klartext heraus.
