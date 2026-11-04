# Text-Editor für Mitwirkende (GitHub Pages)

**Adresse:** https://joergsf4.github.io/Fantasy_Strategy/ (reine Webseite, kein Server, kein Konto zum Bearbeiten nötig; zum Einreichen braucht man ein kostenloses GitHub-Konto).

## Für Texter und Tester
1. Die Seite öffnen, Texte bearbeiten (Gespräche, Fähigkeits-Texte, Geheimnisse, Aufstellungen). **Alles wird automatisch im Browser gesichert** (alle paar Sekunden), man kann die Seite schließen und später weitermachen (gleicher Browser).
2. Oben rechts **„Änderungen einreichen“**: Name eintragen (und optional eine Notiz), dann
   1. **„Datei herunterladen“** (eine Textdatei `fuzaketa-aenderungen-<Name>-<Datum>.txt`),
   2. **„GitHub-Issue öffnen“** (Titel und Text sind vorausgefüllt),
   3. die Datei in das Textfeld des Issues **ziehen**, kurz warten, bis der Link erscheint,
   4. **„Submit new issue“**.
3. „Meine Änderungen zurücksetzen“ (im selben Fenster) verwirft den Arbeitsstand im Browser.

Die Datei ist ein Textdokument mit **JSON-Inhalt** (Endung `.txt`, weil GitHub `.json`-Anhänge oft ablehnt): Format `fuzaketa-aenderungen`, Version 1, Stand des Editors (Commit), Name, Notiz und eine Liste **geänderter Teile** (Kapitel-Teile Einleitung/Abschluss/Kampfgespräche/Rückzug/Ideen, Fähigkeits-Texte, Geheimnisse, Missionsaufstellungen) jeweils mit `before` und `after`.

## Für das Projekt (Maintainer)
1. Die Datei aus dem Issue herunterladen.
2. Im **lokalen Editor** (`python3 tools/dialog_editor/server.py`) oben **„Vorschlag importieren“** wählen. Es erscheint eine Liste aller Teile mit Diff (rot = alt, grün = neu).
   - **„passt“**: Der lokale Text ist noch der, den der Mitwirkende als Ausgangspunkt hatte (vorangehakt).
   - **„Konflikt“**: Lokal wurde inzwischen etwas anderes geändert (nicht vorangehakt, bitte genau ansehen).
   - **„schon enthalten“**: nichts zu tun. Ungültige Teile werden ignoriert.
3. Angehakte Teile übernehmen, durchsehen, **Speichern**: Die Prüfung des Servers (`tools/dialog_editor/server.py`) läuft dabei wie bei eigenen Änderungen, ungültige Daten werden abgelehnt. Danach committen.

## Technik
- **Bau:** `python3 tools/dialog_editor/build_pages.py [Ordner]` (Standard `out/pages`) erzeugt `index.html` (mit `<meta name="fz-static">`), die Momentaufnahme `data.json`, `missions.json`, `characters.json`, `secrets.json` und verkleinerte Portraits (420 Pixel hoch) samt Schriften, rund 24 MB.
- **Veröffentlichung:** `.github/workflows/pages.yml` baut und deployt bei jeder Änderung an `game/data/**`, Portraits, Schriften oder `tools/dialog_editor/**` (auch von Hand startbar: `gh workflow run pages.yml`). Pages-Quelle: „GitHub Actions“ (eingerichtet).
- **Mitmach-Modus im Editor:** `api()` in `tools/dialog_editor/index.html` ersetzt die Server-Aufrufe: lesen aus den JSON-Dateien, schreiben in den Browser-Speicher (`localStorage`, Schlüssel `fz-editor-arbeitsstand-v1`). Nicht verfügbar: der Claude-Entwurf. Das Änderungspaket entsteht aus dem Vergleich mit der unveränderten Momentaufnahme.
- **Tests:** `python3 -m unittest tools/dialog_editor/test_build_pages.py tools/dialog_editor/test_server.py`; Ende-zu-Ende mit echtem Browser (Playwright): `python3 tools/dialog_editor/build_pages.py out/pages && node tools/gemini/e2e_pages.mjs` (Laden, Bearbeiten, Sichern, Paket, Neuladen, Import, Konflikt).
- **Hinweis:** Das Repository und die Seite sind öffentlich, der Editor zeigt also **alle** Geschichte-Inhalte inklusive Geheimnissen und Ideen.
