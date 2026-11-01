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

## Zweiter Auslöser-Typ: Strahl über einen Verbündeten (`beam_via_ally`)

Beispiel **Laser-Reflektor** (Robo und Takeda): Steht Takeda auf der geraden Linie zwischen Robo und dem Ziel seines roten oder grünen Lasers, lenkt er den Strahl mit seinem Schwertwirbel um. Der Strahl endet bei Takeda, und alle Figuren im **Umkreis von 2 Feldern um Takeda** bekommen **75 %** der Wirkung: beim roten Laser (×1,8, ignoriert die Hälfte der Verteidigung) werden die **Gegner** getroffen, beim grünen Laser (12 Heilung, Gegengift) die **Verbündeten** geheilt. Das ursprüngliche Ziel profitiert nur, wenn es im Umkreis steht.
- **Daten:** `trigger: {type: "beam_via_ally", by, abilities: [...], via}`, `effects: {reflect_pct, radius, cutin: {unit, title, sub}}`, `scene` wie beim ersten Typ. Der Umkreis und die Prozente stehen im Editor.
- **Ablauf** (`Battle._beam_blocker`, `_run_reflect`): Beim **ersten Mal** erscheinen die Dialogszene (Robo links, Takeda rechts) und der große Polarlicht-Auftritt (`SuperCutin` mit Takeda, Titel „Laser-Reflektor“, Untertitel „Schwertwirbel“, Super-Musik). **Danach** nur ein kurzer Effekt: Strahl zu Takeda, Schwertwirbel, „Reflektiert!“, Strahlen zu den Opfern. Anders als beim Betrunkenen Meister gilt der Effekt **bei jedem Schuss**, nicht nur einmal pro Kampf. Abklingzeit und Statistik zählen für Robo.
- **Kein Hinweis im Spiel:** Der Schuss verhält sich ohne Takeda auf der Linie wie bisher.
- **Nicht modelliert:** Der Simulator kennt die Reflexion nicht, die Gegner-KI nutzt sie nicht.
- Test: `tests/test_reflect.gd`, Editor-Test `test_geheimnis_strahl_ueber_verbuendeten`.

### Wirkungsart „Auffangen“ (`effects.mode: "catch"`): Futter für Brumm
Beispiel **Futter für Brumm** (Hundsfreund und Mira & Brumm): Wirft der Hundsfreund seinen **Knochenwurf** und Mira & Brumm stehen auf der Flugbahn (gerade Linie, Mira zwischen Hundsfreund und Ziel), fängt Brumm einen Knochen auf: Mira & Brumm werden um **8** geheilt und sind **3 Runden satt** (Status `satt`, **25 % weniger erlittener Schaden**, kleines Knochen-Symbol über dem Balken). **Der Angriff selbst bleibt unverändert** (alle drei Knochen treffen wie sonst). Anders als beim Reflektor geht der Strahl also weiter. Beim ersten Mal läuft die Dialogszene (Hundsfreund links, Mira & Brumm rechts), danach nur der kurze Effekt (Knochen fliegt zu Brumm, Sprung, „Mjam!“, +8). Bei Knochenwurf (Reichweite 1–2) ist das nur möglich, wenn das Ziel genau 2 Felder entfernt in gerader Linie steht und Mira dazwischen auf dem ersten Feld.
- **Daten:** `trigger` wie beim Reflektor, `effects: {mode: "catch", heal, status: {id, turns, reduce_pct}}`. `Combat.damage` kennt die Schadensminderung über `mods.reduce_pct` jedes Status.
- Im Editor wählt man bei „Wirkung“ die Wirkungsart (Reflexion oder Auffangen). Test: `tests/test_reflect.gd`, `test_geheimnis_strahl_ueber_verbuendeten`.

### Erkennungszeichen: der Polarlicht-Auftritt
Der große Auftritt mit Polarlicht-Himmel, vergrößerter Figur und Super-Musik (`SuperCutin`) ist das **Erkennungszeichen jedes Geheimnisses**: Er läuft beim ersten Entdecken (nach der Dialogszene), bei beiden Auslöser-Typen (`effects.cutin: {unit, title, sub}`). Im Editor steht er in jedem Geheimnis als eigener Block „Erkennungszeichen“ (neue Geheimnisse haben ihn standardmäßig an). Die Dialogszene kann ein fliegendes Objekt haben (`scene.fly`, zum Beispiel Fass oder Knochen). Test: `tests/test_secrets_cutin.gd`. Ein Geheimnis ansehen: `sh tools/make_clip.sh <id>` nimmt Szene und Effekt mit Ton auf (`out/clips/<id>.mp4`).

### Dritter Auslöser-Typ: Wurf eines Verbündeten (`throw_ally`): Shuriken Regen
**Shuriken Regen** (Muskelaugust und Kage-Schwestern): Wirft Muskelaugust mit seinem **Wurf** die Ninja-Schwestern, fliegen sie **besonders hoch** (Flughöhe 4,2 statt 2,4) und verteilen **aus der Luft einen Regen aus Wurfsternen**. Er trifft alle **Gegner im Umkreis von 2 Feldern um das Landefeld** mit **75 % des normalen Angriffsschadens der Ninjas** (feste Zahl wie beim Reflektor, ohne Positionsboni; Statistik zählt für die Ninjas, ein Verbündeter wird nicht getroffen). Beim ersten Mal Dialogszene (August links, Ninjas rechts, ein Wurfstern fliegt durchs Bild) und Polarlicht-Auftritt, danach nur der Flug mit Regen. Andere geworfene Figuren fliegen wie bisher.
- **Daten:** `trigger: {type: "throw_ally", by, ability, target}`, `effects: {rain_pct, radius, height, cutin}`. Der Typ gilt für jede Fähigkeit mit der Marke `throw_ally`.
- Code: `Battle._throw_with_rain`, `FxNew.shuriken_rain`. Tests: `tests/test_reflect.gd`, `test_geheimnis_wurf_regen`.
