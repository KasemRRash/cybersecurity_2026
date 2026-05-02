# PowerShell-Buildskript fuer Windows.
$ErrorActionPreference = "Stop"
# Bei Fehlern sofort abbrechen, damit kein defekter Build unbemerkt weiterlaeuft.

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Ordner, in dem dieses Skript liegt.
$SrcDir = Join-Path $ScriptDir "src\main\java"
# Ordner mit den Java-Quelldateien.
$OutDir = Join-Path $ScriptDir "out"
# Zielordner fuer die kompilierten .class-Dateien.

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
# Zielordner anlegen, falls er noch nicht existiert.
$Sources = Get-ChildItem -Path $SrcDir -Recurse -Filter *.java | ForEach-Object { $_.FullName }
# Alle Java-Quelldateien rekursiv sammeln.

javac -encoding UTF-8 -d $OutDir $Sources
# Java-Dateien mit UTF-8 kompilieren und die Klassen in out/ speichern.

Write-Host "Fertig. Startbeispiele:"
# Erfolgsmeldung und kurze Beispielbefehle anzeigen.
Write-Host "  java -cp `"$OutDir`" itsicherheit.DhParam <m> <g>"
# Beispiel fuer die DH-Schluesselerzeugung.
Write-Host "  Get-Content cipher.txt | java -cp `"$OutDir`" itsicherheit.Decrypt <m> <g> <priv>"
# Beispiel fuer die Entschluesselung einer dhmsg-Ausgabe aus einer Datei.
