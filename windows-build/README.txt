╔══════════════════════════════════════╗
║   Nexus für Windows — Installation   ║
╚══════════════════════════════════════╝

Nexus ist dein persönlicher Life-Hub: Aufgaben, Schule,
Kalender, E-Mail, VBB-Fahrpläne und mehr — alles offline,
alles lokal auf deinem Gerät.

Version: 0.3 Closed Beta


Installation
────────────

1. Entpacke den Nexus-Ordner an einen beliebigen Ort
   (z.B. Desktop oder Dokumente)

2. Installiere Python 3.9+ (falls noch nicht vorhanden):
   → https://www.python.org/downloads/
   → WICHTIG: "Add Python to PATH" anhaken!

3. Doppelklicke auf "Nexus.bat"

Das war's. Beim ersten Start werden automatisch
alle Abhängigkeiten installiert (1-2 Minuten).


Erster Start
────────────

Beim ersten Start passiert Folgendes automatisch:

  1. Eine Python-Umgebung (venv) wird erstellt
  2. Abhängigkeiten werden installiert
  3. Der Browser öffnet sich mit Nexus

Bei jedem weiteren Start reicht ein Doppelklick auf
"Nexus.bat" — der Browser öffnet sich sofort.


Daten & Speicherort
────────────────────

Alle Daten liegen lokal im Ordner: data\
Nichts wird in die Cloud hochgeladen.


Problemlösung
─────────────

"Python nicht gefunden":
  → Python installieren: https://python.org/downloads
  → "Add Python to PATH" muss angehakt sein
  → Nach der Installation: PC neu starten

Port 5050 belegt:
  → Anderes Programm auf Port 5050 beenden
  → Oder PC neu starten

Nexus.bat schliesst sich sofort:
  → Rechtsklick → "Als Administrator ausführen"

───────────────────────────────────────
Voraussetzungen: Windows 10+, Python 3.9+
Mehr Infos: nexus-lifehub.netlify.app
