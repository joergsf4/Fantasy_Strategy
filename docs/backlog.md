# Backlog

**Stand 2026-11-01:** Die Punkte 1 bis 4 sind umgesetzt (siehe unten, jeweils mit Hinweis). Offene Reste stehen am Ende.

Ideen und offene Punkte, noch nicht gebaut. Stand: 2026-10-31. Entscheidungen des Nutzers sind als solche markiert.

## 1. Mission 7: Der Hafen der Ankunft (neues Biom Wüste) — umgesetzt als „Sandhafen“, `docs/missionen.md`
- Das Schiff aus Mission 6 legt an, die Gruppe betritt ein **neues Biom: Wüste**.
- **Gegner:** Die **Zwillinge Oskar und Maja** sind da und **müssen besiegt werden** (nicht entkommen). Im Spiel fliehen benannte Gegner sonst (`flees`), also braucht die Mission eine Ausnahme (z. B. Missionsfeld `no_flee: ["oskar", "maja"]`, sie sterben dann wirklich oder ziehen sich geschlagen zurück, nach Entscheidung).
- **Biom-Bausteine:** Geländetyp „Sand/Düne“ (z. B. Bewegung teurer), Oase als Heilfeld, Felsen und Kakteen als Deckung, Gelände-Textur und Farbstimmung, Hitzeflimmern und Sandsturm als mögliche Würze. Neue Tiles brauchen Einträge in `Grid.TERRAIN`, `TerrainView` (H, AMP, WT) und Streuobjekte (Kakteen, Palmen) als Sprites.
- **Mechanik-Idee:** Sandsturm verdeckt Sicht (Stealth-ähnlich), Oase als Ziel, Zwillinge nutzen Befehl (Oskar) und Eisigen Blick (Maja), die Gruppe braucht gegenseitige Deckung.
- Offen: Rolle der Trainingsattrappe (aktuell unbenutzt, Einheit liegt in den Daten), Finale auf der Regenten-Insel als Mission 8.

## 2. Statistik am Ende eines Kampfes — umgesetzt (Belohnungsbildschirm: Tabelle je Figur, Auszeichnungen; Rest der Ideen offen: Verlaufskurve, JSON-Export)
Anzeige im Belohnungsbildschirm (`reward_screen.gd`). Der Simulator führt solche Zähler schon je Figur (`SimBattle` `st`: Schaden, erlittener Schaden, Heilung, Besiegte, Fähigkeits-Einsätze). Im Spiel müssten sie in `_strike`, `_deal`, `_apply_effect`, Heilung und Verteidigen mitgezählt werden.

Vorschläge, nach Nutzen sortiert:
- **Überblick:** Runden, Bonusziele (erfüllt oder nicht), Gold und Beute, gefallene und entkommene Gegner (z. B. „Wart entkommen“).
- **Pro Figur:** ausgeteilter Schaden, erlittener Schaden, Heilung, Besiegte, übrige Leben, Fähigkeiten und Gegenstände genutzt.
- **Auszeichnungen mit Humor:** „Prügelknabe“ (meiste Treffer eingesteckt), „Sanitäter“ (meiste Heilung), „Heckenschütze“ (meiste Treffer aus der Ferne), „Zielstrebig“ (meiste Schritte), „Knapp davongekommen“ (überlebt mit den wenigsten Leben).
- **Taktik:** Treffer mit Positionsbonus (Rücken, Flanke, Höhe, Hinterhalt), Gegenschläge, Verteidigen- und Wachsam-Einsätze, Löschen und Rettungen (Feuer, Geisel, Kinder).
- **Verlauf:** Kurve „Leben der Gruppe pro Runde“ oder Balken der Gegnerzahl pro Runde.
- Für das spätere Balancing: Export als JSON neben dem Spielstand, damit echte Spieldaten gegen die Simulation verglichen werden können.

## 3. Gruppe vor der Mission bearbeiten — umgesetzt (Lager, Reiter „Aufstellung“)
- Zu Beginn jeder Mission kann man die Gruppe ändern. **Figuren, die in der Mission keinen Dialog haben, sind frei wechselbar**, Figuren mit Dialogrolle sind fest (Entscheidung des Nutzers, ersetzt „feste Gruppe pro Mission“ teilweise).
- Technik: Pro Mission ermitteln, welche Figuren sprechen (Sprecher in `story_*.json` und in den Auslösern der Mission, `left`/`right`/`speaker`, `$hero` zählt nicht). Der Dialog-Editor (`tools/dialog_editor`) kann das schon auswerten. Dazu ein Wahlbildschirm im Lager (`camp.gd`, Reiter „Aufstellung“ ist bisher nur eine Anzeige).
- Offen: Gruppengröße (heute 6), Mindestanzahl Heiler, Startpositionen der Wahlfiguren, Balancing (die Simulation misst feste Gruppen), Wendy „zu oft dabei“ (Wunsch nach Abwechslung).
### 3.1 Ausrüstung abwesender Figuren
- Wer nicht mitkommt, gibt seine **Ausrüstung** frei: sie geht in den Pool zurück (`Party.pool`) und lässt sich neu verteilen. Rückgabe automatisch beim Entfernen aus der Gruppe, beim Zurückholen wird neu ausgerüstet.

## 4. Mehr Heiler — umgesetzt (Lumi Sternenglanz, Dr. Humbug, ab Mission 7)
Vorschläge des Nutzers: **Magical Girl** und/oder **Quaksalber-Arzt**. Heute heilen Wendy (Heilen), Robo (Grüner Laser) und Claude (Äther) bzw. Brunhilde über Tränke.
- **Magical Girl:** Verwandlungs-Heilerin. Idee: Fähigkeit „Glitzerregen“ (Fläche, heilt alle Verbündeten im Umkreis 1 um ein Ziel) plus kleiner Schutzzauber. Kontrast zu Wendy, die einzeln heilt. Grafik: Porträt mit Emotionen, Karten-Figur.
- **Quaksalber-Arzt:** Komische Heilung mit **berechenbarer** Nebenwirkung (das Spiel hat keinen Zufall). Idee: „Wundersalbe“ heilt viel (14), aber das Ziel ist eine Runde lang „benommen“ vom Geruch (−2 Bewegung). Alternativ „Aderlass“ gegen Gift. Grafik: Porträt mit Emotionen, Karten-Figur.
- Balancing: Heiler-Wert im Simulator messen (E0), nicht stärker als Wendy plus Robo, Gruppen mit zwei Heilern gegen eine messen.

## Weitere offene Punkte (aus der Sitzung)
- ~~Spielstand laden~~ umgesetzt: Das Spiel lädt beim Start den Spielstand, die Kapitelwahl zeigt ihn und kann ihn zurücksetzen.
- **Stachelias Spezialfähigkeit:** Bienen rufen und Heilhonig fallen lassen, später im Team (Entscheidung offen: tritt sie nach Kapitel 5 bei?).
- **Schwierigkeitswahl** (`difficulty.json` ist gemessen, aber nicht verdrahtet) und **Lautstärkeregler** für Musik und Effekte.
- **Brabbel-Laute** beim Dialogtext (Charakter-Laute statt Sprache), Lichtstimmung der Karte überarbeiten.
- **Verwundeter Drache** (Schützling-Mission), **Brückenmission**, **Wachen/Schleichen**, Xiùlán kehrt zurück.
- **Trainingsattrappe:** Einheit samt Wirbel liegt unbenutzt in den Daten, Emotions-Porträts fehlen.
- **Windows-Version** ist nie getestet worden.

## Erledigt: Dörfer als Sprites (2026-11-01)
Dorf-Felder (`V`) zeigen den Dorfplatz-Sprite (Wiese `fx_dorf`, Wüste `fx_dorf_wueste`), brennbare Häuser (`house`) sind Sprites (`fx_haus1..3`, Wüste `fx_haus_wueste1..2`) mit Ruinen (`fx_ruine1..2`). Brennen = dunkler getönter Sprite plus die vorhandenen Flammen, die Spiellogik (Feuer, Löschen, Ruine) ist unverändert. Die alten Klotz-Modelle (`TerrainView._village`, `_house`) sind entfernt.

## Erledigt: Dialog-Editor, Tab „Charaktere“ (2026-11-01)
Übersicht aller Figuren (`GET /api/characters`, `server.characters()`): erstes Auftreten, Spezialfähigkeit (mit Hinweis auf Missions-Fähigkeiten wie die Breitseite), Missions-Zeitstrahl mit Dialogzeilen je Kapitel und Sprung zu den Gesprächen, Werte, Soundprofil, Ausrüstung, Flucht und Rückkehr, Material-Ampel (Porträt, Emotionen, Karten-Figur), Design-Notizen. Filter, Suche, Karten- und Tabellenansicht mit Sortierung.

## Erledigt: Karten-Objekte-Durchgang (2026-11-01)
Alle Kapitel durchgesehen. Ersetzt durch Pixel-Sprites: Truhen (zu und offen, Tausch beim Öffnen), Burg (`C`-Felder), Beutesack-Markierung über Gegnern mit Beute, Hebel des Schalters (gespiegelt, wenn umgelegt), Pfahl mit Seilen bei der Geisel.
**Bewusst als 3D geblieben:** Mauer und Tor (Steinmauer-Optik, vom Nutzer gelobt), Holzsteg (flache Planken auf dem Wasser, Sprites würden dort als stehende Bilder falsch wirken), Gelände mit Bäumen, Büschen, Gras und Steinen (Landschaft, vom Nutzer gelobt), Team-Ring unter den Figuren (Bedienelement).

## Erledigt: Dialog-Editor, Tab „Missionen“ (2026-11-01)
Gruppe und Gegner je Kapitel bearbeiten (`GET /api/missions`, `PUT /api/mission/chN`, schreibt nur `players` und `enemies` der Karte; neue Figuren bekommen automatisch ein freies Landfeld in der Nähe der bisherigen). Story-Prüfung mit der neuen Einheiten-Eigenschaft `intro` (Kapitel der Einführung, aus dem ersten Auftreten gesetzt, in `units.json`): Warnung, wenn eine Figur vor ihrer Einführung steht, Sprecher ohne Platz, Rückkehrer ohne früheren Auftritt, Gruppengröße, kein Heiler. Offen: Positionen per Drag auf der Minikarte ändern, Beute und Sonderwerte der Gegner bearbeiten, Wirkung auf den Simulator (`tools/balance.py`) direkt anzeigen.

## Erledigt: Eichenfurt brennt nicht mehr (2026-11-01)
Kapitel 1 heißt jetzt „Eichenfurt in Gefahr“: Büttel ziehen auf das Dorf zu, es brennt nichts (Titel, Briefing, Einleitung, Abschluss). Kapitel 3 „Mühlbach in Flammen“ bleibt die Feuer-Mission.

## Erledigt: Dr. Humbug ab Mission 3 (2026-11-01)
Siehe `docs/missionen.md`. Mission 3 ist durch den Nachschub (Bogenschütze und Büttel, Runde 4) härter; Messung in `docs/balance.md` Abschnitt 8.

## Erledigt: Fähigkeits-Felder im Charaktere-Tab (2026-11-01)
Pro Figur zwei Freitextfelder „Fähigkeit 1/2“: vorbelegt mit den Fähigkeiten aus dem Spiel (zwei bei Albrecht, eins bei den Kage-Schwestern, das zweite frei), leer bei Figuren ohne Fähigkeit. Gespeichert wird mit dem Speichern-Button oben bzw. Strg+S (`game/data/ability_notes.json`); der Button samt Status, Rückgängig und Strg+S gilt in allen drei Tabs und speichert Gespräche, Missionen und Fähigkeitstexte zusammen, „↺ Spieltext wiederherstellen“ setzt zurück. Das ist ein Entwurfs-Notizblock und ändert Abilities und Balancing nicht. Offen: Übernahme eines Entwurfs als echte Fähigkeit in `abilities.json`.


## Erledigt: 14 neue Fähigkeiten (2026-11-01)
Wollmantel (Wendy), Bärengebrüll (Brumm), Stabwirbel (Lin), Wutanfall (Elisabeth), Bienenkorb (Stachelia), Prost (Brunhilde), Bearhug (Muskelaugust), Kyujutsu (Takeda), Brandbombe (Oskar), Flucht (Maja), Tonikum (Dr. Humbug), Hinterhalt (Kage-Schwestern), Bellen (Hundsfreund), Sternschnuppe (Lumi). Gemeinsame Abklingzeit je Figur. Details und Messwerte: `docs/faehigkeiten_plan.md`, Abschnitt 10.

## Erledigt: Geheime Interaktionen (2026-11-01)
Datengetriebenes System (`secrets.json`, Editor-Tab „Geheimnisse“, Szene mit Sonderbild und Tiefenwirkung, Spielstand merkt gesehene Szenen). Erstes Geheimnis: Brunhilde wirft ein Fass auf Lin, „Betrunkener Meister“ mit Drunken Strike. Details: `docs/geheimnisse.md`. Offen: weitere Geheimnisse (andere Auslöser wie Nachbarschaft oder gemeinsamer Angriff), Sammlung der entdeckten Geheimnisse im Lager, Simulator.

## Erledigt: Bäume, Büsche und Felsen als Sprites (2026-11-01)
Das Terrain setzt statt der 3D-Meshes jetzt Gemini-Pixel-Sprites (`fx_baum_fichte1/2`, `fx_baum_eiche1/2/3`, `fx_busch`, `fx_fels1/2`) als MultiMesh mit `shaders/prop_sprite.gdshader` (volles Billboard wie die Figuren, scharfe Kanten, leichtes Wiegen im Wind) und weichen Bodenschatten (`TerrainView.SPRITES`). Gelbe Birken sind selten. Nicht umgestellt: Gras, Blumen (bleiben Meshes), Holzsteg.

## Erledigt: Musik für den Statistik-Bildschirm (2026-11-01)
Nach einem Sieg läuft fröhliche Musik (`sieg_statistik.mp3`), nach einer Niederlage traurige (`niederlage_statistik.mp3`), beide mit Gemini erzeugt (`tools/gemini/music.mjs`, Originale in `strategie/musik/`). Neu: Nach einer Niederlage zeigt der Statistik-Bildschirm (`RewardScreen` mit `defeat`, `Battle.defeat_summary()`) die Bilanz ohne Beute und den Knopf „Noch einmal versuchen“; vorher begann sofort ein neuer Versuch. Die Kampfmusik startet mit dem neuen Versuch wieder.
- Trailer 3 (ca. 55 s): `tools/make_trailer.sh trailer3`, Ablauf in `game/scripts/trailer3.gd` (ohne Zahlenangaben, ohne Regent und Bienenkorb).

## Erledigt: Kapitelwahl nur per Cheat (2026-11-01)
Normal gibt es keine Kapitelwahl mehr (weiterspielen aus dem Spielstand, ab Kapitel 2 zuerst ins Lager). Der Cheat `brumm` im Hauptmenü schaltet das Testmenü frei, N-N startet ein neues Spiel (`TitleScreen`, `Main._title`, `Main._resume_pick`, Test `tests/test_title.gd`). Eine zweite Programmversion ist damit nicht nötig. Offen: ein Ende nach dem letzten Kapitel (derzeit startet man dort wieder im Lager vor Kapitel 7).
