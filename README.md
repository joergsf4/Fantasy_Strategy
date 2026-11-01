# Strategy Fantasy (Arbeitstitel)

Rundenstrategie im Stil von Fire Emblem und Advance Wars, gebaut mit **Godot 4.7**: 3D-Karten mit rechteckigem Raster, Pixel-Art-Figuren, Anime-Dialoge, Fähigkeiten als Werkzeuge in den Missionen. Ein Spaßprojekt, nicht kommerziell.

## Starten
```
godot --path game
```
Nach „Press Start“ erscheint eine Kapitelauswahl (Testmenü). Steuerung: Maus (Figur wählen, Feld wählen, Menü neben der Figur; Rechtsklick = zurück; im Dialog Linksklick = weiter).

## Inhalt
- `game/` Godot-Projekt (Skripte, Daten als JSON, Shader, Assets)
- `docs/` Kampfsystem, Figuren, Missionen, Balancing-Bericht
- `tools/` Hilfswerkzeuge: Freistellen der Bilder (`chroma_key.py`), UI-Texturen (`make_ui.py`), Gemini-Automatisierung (`gemini/`), Balancing (`balance.py` mit grafikfreiem Simulator in `game/sim/`), Trailer und Thumbnail
- `strategie/` Original-Bilder (Gemini) auf Greenscreen

## Dialog-Editor
```
python3 tools/dialog_editor/server.py     # dann http://127.0.0.1:8765 im Browser öffnen
```
Weboberfläche für alle Gespräche (Einleitung, Abschluss, Gespräche im Kampf mit Auslösern, Rückzug benannter Gegner): Texte bearbeiten, Figuren per Drag-and-Drop zuordnen, Zeilen umsortieren, Vorschau wie im Spiel, neue Gespräche aus einer Beschreibung entwerfen (braucht die Claude-CLI). Zweiter Tab **Charaktere**: Übersicht aller Figuren (erstes Auftreten, Spezialfähigkeit, Missionen mit Dialogzeilen, Werte, Notizen aus `docs/figuren.md`, Material-Check) als Karten oder Tabelle. Dritter Tab **Missionen**: Gruppe und Gegner jedes Kapitels per Drag-and-Drop ändern (Figuren aus der Palette in die Listen ziehen, per ✕ oder auf die Palette zurück entfernen) mit Minikarte und **Story-Warnungen** (z. B. Hundsfreund in Kapitel 1, bevor er eingeführt wird; Sprecher ohne Platz; Rückkehrer ohne früheren Auftritt). Gespeichert wird in `game/data/map_chN.json`. Nur Python-Standardbibliothek. Test: `python3 -m unittest tools/dialog_editor/test_server.py`.

## Tests
```
godot --headless --path game --script tests/test_combat.gd
```
(ebenso `test_abilities`, `test_sim`, `test_objects`, `test_fire`, `test_mission` und weitere in `game/tests/`)

## Hinweise
- **KI-generierte Inhalte:** Alle Figuren- und Effektbilder (`strategie/`, `game/assets/portraits|tokens|fx`) und die Musik (`game/assets/audio/`) wurden mit Google Gemini erzeugt. Programmcode und Daten entstanden mit Claude Code. Das Projekt ist ein nicht kommerzielles Hobbyprojekt.
- Schriften: Cinzel Decorative und IM Fell English (SIL Open Font License, Lizenztexte im Ordner `game/assets/fonts/`).
