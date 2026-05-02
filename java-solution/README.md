# Java-Portierung der IT-Sicherheit-A1-Loesung

Pure Java, keine Frameworks und keine externen Bibliotheken.

## Build

```powershell
.\build.ps1
```

Falls PowerShell-Skripte gesperrt sind:

```cmd
build.bat
```

Unter Linux/WSL:

```sh
chmod +x build.sh run-java.sh
./build.sh
```

Die Linux-Skripte verwenden automatisch OpenJDK 21 unter
`/usr/lib/jvm/java-21-openjdk-amd64`, falls dein `java` noch auf Java 11 zeigt.

Alternativ direkt:

```powershell
javac -encoding UTF-8 -d out (Get-ChildItem -Recurse src\main\java\*.java)
```

## Programme

### DH-Parameter und Schluessel erzeugen

```powershell
java -cp out itsicherheit.DhParam
java -cp out itsicherheit.DhParam <m> <g>
```

Ausgabe:

```text
m: <hex>
g: <hex>
priv: <hex>
pub: <hex>
```

### dhmsg-Ausgabe entschluesseln

```powershell
Get-Content cipher.txt | java -cp out itsicherheit.Decrypt <m> <g> <priv>
```

Die Eingabe muss wie bei der Python-Version in der ersten Zeile `MyPubkey: <hex>` enthalten.

### Wrapper wie run.sh

```powershell
java -cp out itsicherheit.Run <m> <g> <prof_pubkey>
java -cp out itsicherheit.Run <m> <g> <prof_pubkey> --decrypt
```

Der Wrapper cached das eigene Schluesselpaar im Temp-Verzeichnis und entfernt es nach `--decrypt`.

Mit `dhmsg` in WSL:

```sh
M=e4eea0d7a7430ca16823
G=c1b0f4f1b8d891413ece
PROF_PUB=71d00f8559aa5c90c420

./run-java.sh "$M" "$G" "$PROF_PUB"
# Den ausgegebenen Public Key an dhmsg uebergeben:
echo 'Hello World!' | ../dhmsg "$M" "$G" "<mein_pubkey>" | ./run-java.sh "$M" "$G" "$PROF_PUB" --decrypt
```

Schnelltest:

```sh
chmod +x test-dhmsg.sh
./test-dhmsg.sh
```

Vollstaendiger Anforderungstest:

```sh
chmod +x test-requirements.sh
./test-requirements.sh
```
