@echo off
rem Windows-cmd-Buildskript fuer die Java-Loesung.
setlocal
rem Variablen bleiben lokal in diesem Skript und verschmutzen nicht die Shell.

set "SCRIPT_DIR=%~dp0"
rem Ordner, in dem build.bat liegt.
set "SRC_DIR=%SCRIPT_DIR%src\main\java"
rem Ordner mit den Java-Quelldateien.
set "OUT_DIR=%SCRIPT_DIR%out"
rem Zielordner fuer die kompilierten .class-Dateien.

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
rem Zielordner anlegen, falls er fehlt.

javac -encoding UTF-8 -d "%OUT_DIR%" "%SRC_DIR%\itsicherheit\*.java"
rem Alle Java-Dateien im Paket itsicherheit kompilieren.
if errorlevel 1 exit /b %errorlevel%
rem Bei javac-Fehlern mit demselben Fehlercode abbrechen.

echo Fertig. Startbeispiele:
rem Erfolgsmeldung und kurze Beispielbefehle anzeigen.
echo   java -cp "%OUT_DIR%" itsicherheit.DhParam ^<m^> ^<g^>
rem Beispiel fuer die DH-Schluesselerzeugung.
echo   type cipher.txt ^| java -cp "%OUT_DIR%" itsicherheit.Decrypt ^<m^> ^<g^> ^<priv^>
rem Beispiel fuer die Entschluesselung einer dhmsg-Ausgabe aus einer Datei.
