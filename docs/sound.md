# Soundeffekte

**Erzeugung:** `python3 tools/make_sfx.py [Teil-Name]` synthetisiert alle Klänge (numpy/scipy, feste Seeds, also reproduzierbar) nach `game/assets/sfx/<name>_<n>.wav`, 1–3 Varianten je Klang. Danach einmal `godot --headless --path game --import`.

**Schichten im Nahkampf:** Schwung (Whoosh je Waffe) + Waffenschicht (`w_wood`, `w_metal`, `w_fist`) + Zielschicht (`t_armor`, `t_wood`, `t_flesh`, `t_stone`) + Akzent `crit` bei Positionsbonus (Rücken, Flanke, Höhe, Hinterhalt). Sonderfall `fist+flesh` = `t_face` („Faust auf Gesicht“). Jede Figur trägt in `units.json` die Marken `weapon` (wood, metal, fist) und `body` (armor, wood, flesh, stone). Standard: Faust und Fleisch.

**Zuordnung:** `game/data/sfx.json` (Waffe, Ziel, Kombinationen, Fernkampf je Figur, Fähigkeiten je Phase, Ereignisse). Eine Angabe ist ein Name, ein Objekt `{s, db, pitch, delay}` oder eine Liste; `@melee` löst die Waffe/Ziel-Schichten aus. Fähigkeitsphasen: `windup`, `cast`, `shot`, `hit`, `heal`.

**Code:** `scripts/sfx.gd` (Abspielen, 24 Stimmen, Bus „SFX“, zufällige Variante und leichte Verstimmung, Klick-/Hover-Ton für alle Buttons automatisch). Eingehängt in `fx.gd` (Fähigkeiten, Treffer, Tod, Verteidigen) und `battle.gd` (Schwung, Welt, Beute, Rundenbeginn, Sieg/Niederlage).

**Soundlabor:** im Levelwähler (Testmenü), spielt jede Waffe × Ziel-Kombination, Fähigkeiten, Ereignisse und alle Rohklänge einzeln.

**Noch offen:** Klänge sind Synthese und gehören abgehört und gegebenenfalls durch freie Aufnahmen ersetzt. Lautstärkeregler im Spiel (Musik, Effekte), Brabbel-Laute beim Dialogtext, Umgebung (Feuer-Loop `fire_loop` liegt bereit, ist nicht eingebunden).
