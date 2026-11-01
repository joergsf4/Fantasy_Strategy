# Geheime Interaktionen

Zwischen bestimmten Figuren gibt es versteckte Wechselwirkungen. Der Spieler findet sie durch Ausprobieren: Es gibt keinen Hinweis im Spiel.

## Wie es funktioniert

- **Auslöser** (`ability_on_ally`): Figur A setzt eine Fähigkeit, die sonst auf Gegner zielt, auf einen Verbündeten B ein. B erscheint dann als Ziel. Ohne passendes Geheimnis ist B kein Ziel. Im Zielhinweis steht nur „Fähigkeit: A → B“, kein Schaden und keine Erklärung.
- **Wirkung** (bis Kampfende): Angriffsbonus in Prozent (dauerhafter Status, mindestens +1), eine neue Fähigkeit, ein Statussymbol. Der Verbündete nimmt keinen Schaden.
- **Szene** beim ersten Mal (`SecretScene`, Erbe von `Dialogue`): das bekannte Format, links ein Charakter, rechts der zweite, dazu Sonderbild mit Tiefenwirkung: zwei Charakterebenen und ein fliegendes Vordergrundobjekt (Fass) verschieben sich gegeneinander (Maus und leichtes Schwanken), Banner „Geheime Interaktion“, Schaumausbruch und Goldblitz. Die Szene liegt wie jeder Dialog vor der (leicht abgedunkelten) Karte, nicht vor einem eigenen Hintergrundbild, damit sie zu jedem Schauplatz passt. Später läuft nur noch der Effekt. Gesehene Szenen speichert `Party.secrets_seen` im Spielstand.
- Ein Geheimnis löst pro Kampf einmal aus.

## Daten

Jedes Geheimnis ist zuerst eine **Idee**: `name`, `characters` (beteiligte Figuren) und `prompt` (Freitext, was passieren soll; wird später zur Umsetzung an Claude gegeben). Die technische Umsetzung (`trigger`, `effects`, `scene`) ist optional. **Aktiv im Spiel sind nur Einträge mit `trigger`** (`Secrets.all()` ignoriert reine Ideen). Im Editor steht oben der Prompt mit der Figurenauswahl; Auslöser, Wirkung und Szene liegen im aufklappbaren Bereich „Technische Umsetzung“ und lassen sich anlegen oder wieder entfernen.

`game/data/secrets.json` (bearbeitbar im Dialog-Editor, Tab **Geheimnisse**: Auslöser, Wirkung, Bilder und Zeilen der Szene mit Vorschau; gespeichert mit dem gemeinsamen Speichern-Button). Szenenbilder sind Porträts (`game/assets/portraits/sec_*.png`, Gemini, freigestellt mit `tools/chroma_key.py neu`) (Hintergrundbilder gibt es nicht mehr; `chroma_key.py bg` und der Auftrag `bg_betrunken` in `run.mjs` bleiben als Werkzeug). Code: `scripts/secrets.gd`, `Battle._run_secret`, `scripts/secret_scene.gd`, Animation `FxNew.secret_reveal`.

## Erstes Geheimnis: Betrunkener Meister

Brunhilde wirft ihren Fasswurf auf Meister Lin. Lin bekommt Bierlaune (goldene Aura, Blasen und Schaum): Angriff +10 %, neue Fähigkeit **Drunken Strike** (3 Hiebe zu je ×0,9, ignoriert 30 % der Verteidigung, taumelnde Anläufe von der Seite, „KRACK“ beim letzten Hieb, Abklingzeit 3, gemeinsam mit Stabwirbel). Der Simulator kennt Geheimnisse nicht.

## Neues Geheimnis anlegen

Im Editor-Tab „Neues Geheimnis“: Figur und Fähigkeit wählen (nur Fähigkeiten mit Gegner-Ziel), Verbündeten wählen, Wirkung eintragen, Bilder und Text der Szene setzen. Eigene Bilder: in `tools/gemini/run.mjs` Aufträge `sec_<name>_<figur>` (Porträt, Figur links bzw. rechts) anlegen, dann `chroma_key.py neu`. Neue Fähigkeiten stehen in `abilities.json`.

## Super-Attacke (Drunken Strike)

Fähigkeiten mit `"super": true` in `abilities.json` bekommen einen besonderen Auftritt (`SuperCutin`, `Battle._super_cutin`): ein Polarlicht-Himmel (`shaders/aurora.gdshader`, animiert, mit Sternen), davor der stark vergrößerte Chibi der Figur (gleitet mit Nachbildern herein, taumelt leicht), Kinobalken, Funkenflug, der Name der Attacke schlägt ins Bild (`super_sub` als Untertitel), Weißblitz, danach beginnt die eigentliche Attacke. Dazu läuft eigene Musik (`assets/audio/super_attack.mp3`, „Sway of the Iron Fan“, ca. 1 Minute, mit Gemini erzeugt, Original in `strategie/musik/`): die Kampfmusik wird leiser, die Super-Musik blendet nach der Attacke aus. Jede weitere Fähigkeit lässt sich mit `"super": true` genauso aufwerten. Neue Musik: `node tools/gemini/music.mjs "<Beschreibung>" <ausgabe.mp3>`.
