# Backlog

**Stand 2026-11-01:** Die Punkte 1 bis 4 sind umgesetzt (siehe unten, jeweils mit Hinweis). Offene Reste stehen am Ende.

Ideen und offene Punkte, noch nicht gebaut. Stand: 2026-10-31. Entscheidungen des Nutzers sind als solche markiert.

## 1. Mission 7: Der Hafen der Ankunft (neues Biom Wüste) — umgesetzt als „Sandhafen“, `docs/missionen.md`
- Das Schiff aus Mission 6 legt an, die Gruppe betritt ein **neues Biom: Wüste**.
- **Gegner:** Die **Zwillinge Oskar und Maja** sind da und **müssen besiegt werden** (nicht entkommen). Im Spiel fliehen benannte Gegner sonst (`flees`), also braucht die Mission eine Ausnahme (z. B. Missionsfeld `no_flee: ["oskar", "maja"]`, sie sterben dann wirklich oder ziehen sich geschlagen zurück, nach Entscheidung).
- **Biom-Bausteine:** Geländetyp „Sand/Düne“ (z. B. Bewegung teurer), Oase als Heilfeld, Felsen und Kakteen als Deckung, Gelände-Textur und Farbstimmung, Hitzeflimmern und Sandsturm als mögliche Würze. Neue Tiles brauchen Einträge in `Grid.TERRAIN`, `TerrainView` (H, AMP, WT) und Streuobjekte (Kakteen, Palmen) als Sprites.
- **Mechanik-Idee:** Sandsturm verdeckt Sicht (Stealth-ähnlich), Oase als Ziel, Zwillinge nutzen Befehl (Oskar) und Eisigen Blick (Maja), die Gruppe braucht gegenseitige Deckung.
- Offen: Rolle der Trainingsattrappe (aktuell unbenutzt, Einheit liegt in den Daten), Finale auf der Regenten-Insel als Mission 8.

## 2. Statistik am Ende eines Kampfes — umgesetzt (Belohnungsbildschirm: Tabelle je Figur, Auszeichnungen, Verlaufsgrafik und JSON-Export seit 2026-11-09)
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

### 3.2 Automatisch ausrüsten — umgesetzt
- Im Lager unter **Ausrüstung** füllt „Automatisch ausrüsten“ freie Plätze der aktuellen Gruppe mit passenden Gegenständen aus dem Vorrat. Bereits angelegte Ausrüstung bleibt erhalten.
- Die Verteilung berücksichtigt Tragevoraussetzungen, Rollen, Werte und Fähigkeiten; beispielsweise kommt das **Fernrohr** für **Robo** infrage. Die Bewertung ist eine Heuristik und kann manuell angepasst werden.

## 4. Mehr Heiler — umgesetzt (Lumi Sternenglanz, Dr. Humbug, ab Mission 7)
Vorschläge des Nutzers: **Magical Girl** und/oder **Quaksalber-Arzt**. Heute heilen Wendy (Heilen), Robo (Grüner Laser) und Claude (Äther) bzw. Brunhilde über Tränke.
- **Magical Girl:** Verwandlungs-Heilerin. Idee: Fähigkeit „Glitzerregen“ (Fläche, heilt alle Verbündeten im Umkreis 1 um ein Ziel) plus kleiner Schutzzauber. Kontrast zu Wendy, die einzeln heilt. Grafik: Porträt mit Emotionen, Karten-Figur.
- **Quaksalber-Arzt:** Komische Heilung mit **berechenbarer** Nebenwirkung (das Spiel hat keinen Zufall). Idee: „Wundersalbe“ heilt viel (14), aber das Ziel ist eine Runde lang „benommen“ vom Geruch (−2 Bewegung). Alternativ „Aderlass“ gegen Gift. Grafik: Porträt mit Emotionen, Karten-Figur.
- Balancing: Heiler-Wert im Simulator messen (E0), nicht stärker als Wendy plus Robo, Gruppen mit zwei Heilern gegen eine messen.

## Weitere offene Punkte (aus der Sitzung)
- **Geheimnis-Musik — korrigiert:** Beim Laser-Reflektor wurde die Musik nach bereits gesehener Dialogszene nicht beendet. Der Polarlicht-Auftritt blendet die Musik nun auch bei wiederholter Auslösung aus.
- **Knochenwurf — umgesetzt:** Drei Treffer mit je ×0,75 Schaden und 50 % Rüstungsdurchdringung statt ×0,5 ohne Durchdringung. Balancing im Spiel weiter beobachten.
- **Sexy Jutsu — umgesetzt:** Die Kage-Schwestern können das Geheimnis direkt neben Maja unabhängig von ihrer Blickrichtung auslösen. Der normale Hinterhalt bleibt unverändert.
- ~~Spielstand laden~~ umgesetzt: Das Spiel lädt beim Start den Spielstand, die Kapitelwahl zeigt ihn und kann ihn zurücksetzen.
- **Stachelias Spezialfähigkeit:** Bienen rufen und Heilhonig fallen lassen, später im Team (Entscheidung offen: tritt sie nach Kapitel 5 bei?).
- ~~Schwierigkeitswahl und Lautstärkeregler~~ umgesetzt (2026-11-09): Pause-Menü, Reiter „Ton und Spiel“ (Musik, Effekte, Schwierigkeit Leicht/Normal/Schwer = ×0,8/×1,0/×1,2 auf Leben und Angriff der Gegner).
- **Brabbel-Laute** beim Dialogtext (Charakter-Laute statt Sprache), Lichtstimmung der Karte überarbeiten.
- **Verwundeter Drache** (Schützling-Mission), **Brückenmission**, **Wachen/Schleichen**, Xiùlán kehrt zurück.
- **Trainingsattrappe:** Einheit samt Wirbel liegt unbenutzt in den Daten, Emotions-Porträts fehlen.
- ~~Windows-Version~~ ist getestet: läuft (laut Nutzer „works like a charm“).

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
- Trailer 5 (ca. 113 s, Hollywood-Dramaturgie mit Schrifttafeln, Stille, Wendung als Silhouette, Titelkarte, Sack-Nachspann): `tools/make_trailer.sh trailer5`, Ablauf in `game/scripts/trailer5.gd`, Ergebnis `out/trailer/trailer5.mp4`.
- Trailer 3 (ca. 55 s): `tools/make_trailer.sh trailer3`, Ablauf in `game/scripts/trailer3.gd` (ohne Zahlenangaben, ohne Regent und Bienenkorb).

## Erledigt: Kapitelwahl nur per Cheat (2026-11-01)
Normal gibt es keine Kapitelwahl mehr (weiterspielen aus dem Spielstand, ab Kapitel 2 zuerst ins Lager). Der Cheat `brumm` im Hauptmenü schaltet das Testmenü frei, N-N startet ein neues Spiel (`TitleScreen`, `Main._title`, `Main._resume_pick`, Test `tests/test_title.gd`). Eine zweite Programmversion ist damit nicht nötig. Offen: ein Ende nach dem letzten Kapitel (derzeit startet man dort wieder im Lager vor Kapitel 7).

## Erledigt: Brabbel-Laute und Gruppenwahl vor der Runde (2026-11-01)
- **Brabbel-Laute:** Beim Tippen jedes Dialogtextes klingt bei jedem zweiten Buchstaben ein kurzer Laut der sprechenden Figur (Klangfarbe und Tonhöhe je Figur, z. B. Robo piepst, Wendy blökt, Hundsfreund bellt, Stachelia surrt, Sack „pomp“). Zuordnung: `voices` in `game/data/sfx.json`, Klänge `v_*` aus `tools/make_sfx.py`, Test `tests/test_babble.gd`. Neue Figuren brauchen einen Eintrag, sonst gilt die Standardstimme.
- **Gruppenwahl vor der Runde:** Nach der Einleitung und vor dem Kampf erscheint die Gruppenwahl (`SquadSelect`): Wer im Kapitel spricht, ist als „🔒 Story“ gesperrt, alle anderen Plätze lassen sich mit den freigeschalteten Helden tauschen. Sie erscheint nur, wenn es etwas zu wählen gibt (`SquadSelect.has_choice`), auch bei Start über das Testmenü. Die Aufstellung im Lager bleibt zusätzlich bestehen. Test `tests/test_squad_select.gd`.

## Idee (später): Kürbis-Rätsel
Die Gruppe trifft **drei Kürbisse mit lustigen Gesichtern**, die dem Spieler ein **einfaches Rätsel** stellen. Noch offen: wo in der Geschichte (Mission, Zwischenszene, Nebenbegegnung), Art des Rätsels (Texträtsel mit Antwortauswahl im Dialog oder Rätsel im Gelände), Belohnung, Gesichter als Gemini-Sprites. Bräuchte eventuell ein neues Dialog-Element mit Antwortauswahl.

## Erledigt: Wüstenlicht „Hollywood-Mexiko“ (2026-11-01)
Im Biom Wüste (Kapitel 7 und 8) liegt ein gelb-orange Farbfilter über dem Bild (`shaders/grade_mexiko.gdshader`, Schicht unter dem HUD): warme gelbe Mitten, braun-orange Schatten, etwas weniger Sättigung, mehr Kontrast, leichter Dunst und Hitzeflimmern. Dazu tiefere, wärmere Sonne mit längeren Schatten (`Battle._apply_desert_light`). Abschalten pro Karte mit `"grade": "none"` in der Kartendatei; Stärke über die Uniforms des Shaders (`tint`, `saturation`, `haze`, `vignette`).

## Erledigt/Offen: Robina als Held (2026-11-01)
Der Panzer aus Mission 8 ist jetzt ein vollwertiger Held (`panzer` in `units.json`, `hero: true`, `from: 9`, Rolle Tank, Breitseite, Stimme). Fähigkeit 2 ist die **Dampframme** (umgesetzt, 2026-11-03).

## Erledigt: Vollbild, Pause-Menü, Hauptmenü mit Fortfahren (2026-11-01)
- Das Spiel startet im **Vollbild** (`PauseHost.set_fullscreen`, F11 schaltet um; nicht in Screenshot- und Trailer-Modi).
- **Esc** öffnet das Pause-Menü (`PauseMenu`, `PauseHost`): Weiter, Speichern, Vollbild an/aus, Beenden (mit Rückfrage). Das Spiel ist dabei angehalten. Gespeichert wird der Stand nach der letzten geschafften Mission (kein Speichern mitten im Kampf); Beenden speichert vorher.
- **Automatisches Speichern** nach jeder geschafften Mission war schon da, jetzt mit Meldung.
- **Hauptmenü** mit *Fortfahren (Kapitel X)*, *Neues Spiel* (mit Rückfrage) und *Beenden* statt „Press Start“ und N-N (`TitleScreen.interactive`). Test `tests/test_title.gd`.
- Offen: Speichern mitten im Kampf, Lautstärkeregler im Pause-Menü, Optionen (Sprache, Tasten).

## Erledigt: Wasser und Schiff (2026-11-01)
- **Wasser** (`shaders/water.gdshader`): dezente, langsam zum Ufer laufende Wellenlinien, weite Dünung auf offenem Wasser, feine Glitzerpunkte.
- **Schiff** (`shaders/ship_sprite.gdshader`, `Battle._make_ch5_object`): Der Rumpf taucht ins Wasser ein (unterer Rand blendet in Wasserfarbe aus, wogende weiße Wasserlinie), dazu zwei atmende Schaumringe und ein dunkler Wasserschatten, sanftes Schaukeln. Kapitel 6 und 7.

## Erledigt: Aufgeräumte Anzeige über den Köpfen (2026-11-01)
Standardmäßig nur ein **Lebensbalken** (`shaders/hpbar.gdshader`, Teamfarbe, grün/gelb/rot). **Lebenszahl und alle Status** (je eine Zeile mit Restdauer) erscheinen bei Auswahl, Hover und mit gedrückter **Alt**-Taste. **Status-Symbole** (Betäubt, Spott, Wut, Beflügelt, Übel) stehen als Reihe über dem Balken mit kleiner Restdauer, höchstens drei, der Rest als „+N“ (`Fx.sync_status`, `_arrange_icons`). **Kurzmeldungen** laufen in einer Warteschlange je Figur (`Battle._popup`): gestaffelt, gleiche Texte als „×N“, höchstens drei gleichzeitig, abwechselnd links und rechts neben der Figur; Schaden groß, Heilung mittel, Status klein. **Fähigkeitsnamen** erscheinen als Banner oben im Bild (`Battle._banner`). Alle Positionen laufen entlang der Kamera-Hochachse (`Battle._place_overlays`), weil die Kamera steil von oben schaut und Welt-Höhen sonst gestaucht wären. Test `tests/test_popups.gd`.

## Erledigt: Geheimnisse als Freitext-Ideen (2026-11-01)
Der Editor-Tab „Geheimnisse“ arbeitet jetzt mit einem **Freitext-Prompt** und der **Auswahl der beteiligten Figuren**; Auslöser, Wirkung und Szene sind optional (aufklappbar). Einträge ohne technische Umsetzung gelten als Idee und sind im Spiel nicht aktiv. Test: `tools/dialog_editor/test_server.py` (`test_geheimnis_als_freitext_idee_ohne_technik`).

## Erledigt: Geheimnis „Laser-Reflektor“ (2026-11-01)
Zweiter Auslöser-Typ `beam_via_ally` (Strahl über einen Verbündeten umlenken), erstes Beispiel Robo und Takeda: roter Laser trifft die Gegner, grüner Laser heilt die Verbündeten im Umkreis 2 um Takeda mit 75 %. Beim ersten Mal Dialogszene und Polarlicht-Auftritt, danach kurzer Effekt. Der Editor-Tab „Geheimnisse“ kennt den neuen Typ (Auslöser-Typ-Auswahl). Die Dialoge sind vorläufig (von Claude erdacht, der Nutzer verfeinert sie später). Offen: Feinschliff der Dialoge und Werte.

## Erledigt: Geheimnis „Futter für Brumm“ (2026-11-01)
Dritte geheime Interaktion (Hundsfreund wirft Knochen, Mira & Brumm stehen auf der Flugbahn): Heilung 8 und Status „Satt“ (3 Runden, −25 % erlittener Schaden), der Angriff läuft unverändert weiter. Dafür neue Wirkungsart `catch` beim Auslöser-Typ `beam_via_ally`. Dialoge von Claude erdacht (vorläufig), kein Polarlicht-Auftritt (im Editor optional zuschaltbar). Hinweis: Knochenwurf hat nur Reichweite 1–2, der Auslöser tritt daher nur bei Ziel in genau 2 Feldern Abstand auf.

## Erledigt: Geheimnis „Shuriken Regen“ (2026-11-01)
Dritter Auslöser-Typ `throw_ally`: Muskelaugust wirft die Kage-Schwestern höher, aus der Luft regnet es Wurfsterne (75 % des Angriffsschadens, Umkreis 2 um das Landefeld). Szene mit Wurfstern, Polarlicht-Auftritt als Erkennungszeichen, Editor-Typ „Einen Verbündeten werfen“. Dialoge von Claude erdacht (vorläufig).

## Erledigt: Geheimnis „Woll im Überfluss“ (2026-11-01)
Vierter Auslöser-Typ `ability_near_ally`: Kanone von Elisabeth mit Wendy auf einem Nachbarfeld löst Wendys Wollmantel auf alle Verbündeten im Umkreis 2 aus (normale Abklingzeit, nur wenn bereit). Szene, Polarlicht-Auftritt, Editor-Typ „Verbündeter in der Nähe erschrickt“. Dialoge von Claude erdacht (vorläufig).

## Erledigt: Geheimnis „Inspiration von oben“ (2026-11-01)
Fünfter Auslöser-Typ `hit_near_ally`: Lumis Sternschnuppe trifft einen Gegner, Albrecht steht daneben → 2 Runden +25 % Angriff. Szene, Polarlicht-Auftritt, Status-Symbol, Editor-Typ „Verbündeter neben dem getroffenen Gegner“. Dialoge von Claude erdacht (vorläufig).

## Entscheidung: Geheimnisse nicht balancen (2026-11-02)
Der frühere Punkt „Simulator kennt Geheimnisse nicht“ ist **gestrichen**: Geheimnisse gehören absichtlich nicht ins Balancing (Spieler müssen sie nicht entdecken). Ungleiche Stärke (Laser-Reflektor sehr stark, Shuriken Regen schwach) ist vorerst okay. Siehe `docs/geheimnisse.md`.

## Erledigt: Nur kennengelernte Helden wählbar (2026-11-02)
In Gruppenwahl und Lager-Aufstellung sind nur Helden wählbar, die man schon kennengelernt hat (`Party.join_mission`): zählt `from` (wenn gesetzt), sonst `intro` (erstes Auftreten in der Geschichte). Gruppenwahl (nach der Einleitung) zählt auch Helden, die in der Einleitung dieser Mission auftreten; das Lager vor der Mission nur frühere Auftritte. Kapitel 1: nur die sechs Startfiguren, also keine Wahl; Takeda ab 3, Kage-Schwestern ab 4. Die nie eingeführte Figur **Claude (Flaschengeist)** wurde entfernt (2026-11-08); seine Fähigkeit Polymorph bleibt als unbenutzter Baustein in den Daten.

## Mission 9 (Festung im Gebirge)
Gebaut (`ch9`): Wart ohne Flucht, Frischlinge als eine Figur, Regent als Strohmann in weinerlicher Grafik. Offen: Balancing im Simulator (Ziel `defeat`), Gruppenwahl und Sprecher-Sperre prüfen, Anschluss-Mission zur größeren Bedrohung.

## Für morgen (Stand 2026-11-02)

### A. Neuer Gegenspieler: Professor Kugelblitz (Mission 12, die übernächste Mission)
- Er hat die **Kinder aus dem Waisenhaus** (Lotte hat berichtet) in seiner Gewalt. Mit seiner **futuristischen Maschine** und dem **magischen Honig als Katalysator** will er den Kindern die Energie entziehen und sie **dem Meister zuführen**. Das gibt dem Honig-Raub aus Mission 11 (Stachelia, Zwillinge) seinen Sinn.
- Nötig: Porträt (neutral, lachend, wütend), Chibi, Einheit in `units.json`, Maschine als Karten-Objekt (Sprite) mit Mission-Mechanik (z. B. Energieanzeige, die steigt, solange die Kinder angeschlossen sind; Ziel: Maschine zerstören oder abschalten und die Kinder befreien). Reihenfolge: Mission 11 → Mission 12 (Fluss, siehe B) → Mission 13 Kugelblitz.

### B. Mission 12: Fluss mit hochgezogener Zugbrücke (Frischlinge) — umgesetzt
- Karte vom **Fluss geteilt**, die **Frischlinge** haben die **Zugbrücke hochgezogen** (zunächst als „gesprengt“ geplant); die Helden kommen nicht einfach hinüber. **Mechanik-Ideen gesucht.** Vorschläge zum Auswählen:
  - **Brücke reparieren:** Material oder Aktion (Held steht mehrere Runden an der Bruchstelle, mit Balken aus Holzfeldern), Frischlinge stören dabei; Fortschritt wie bei „capture“.
  - **Furt und Boote:** eine flache Stelle (Bewegung 2) flussaufwärts, ein Boot am Ufer (Objekt, trägt 2 Figuren), Fähigkeiten wie Wurf (Muskelaugust) und Schiffs-Breitseite als Alternativen.
  - **Fernkampf-Duell über den Fluss:** Bogen, Kanone, Laser, Robo reflektiert; nur Reichweite und Flug kommen hinüber, der Rest sucht den Weg.
  - **Hebel-Rätsel:** Ein Hebel auf der anderen Seite senkt eine Zugbrücke; erst ein Trupp übersetzen (Flieger, Wurf), dann öffnen.
  - **Strömung:** Fluss mit Strömung schiebt Figuren (Wasserfeld, schnell), Gegner stürzen von Stegen.
- Die Frischlinge (eine Figur aus drei Schweinen, Wart ist tot) fliehen wie üblich, Rachefaden aus Mission 9.

### C. Upgradesystem verbessern (Sack, Ausrüstung) — umgesetzt, siehe `docs/fortschritt.md` (Stufen 1 bis 4, Sortiment je Kapitel, Verkauf, Heldenstufen, Zielkurve)
- **Problem:** Sack verkauft immer dieselben Waffen und Rüstungen. Die Menge ist schon begrenzt (gut), aber die Truppe ist schnell komplett ausgerüstet.
- **Ziel:** Mit der Zeit gibt es **immer bessere Ausrüstung** (Stufen, die mit den Kapiteln im Sortiment erscheinen). Es ist **in Ordnung, wenn man mal nicht genug Geld** für die neue Waffe oder Rüstung hat; das Geld darf knapp sein.
- **Ideen:** Sortiment je Kapitel (Stufe 1 bis 4, `items.json` mit `from`), Aufwertung statt Neukauf (Schmiede-Stufen gegen Material), Preise steigen, alte Ausrüstung lässt sich verkaufen (Teilbetrag), seltene Angebote nur einmal, Beute- und Geheimnis-Belohnungen als Ausrüstung. Balancing mit dem Simulator prüfen (Gold-Einnahmen je Mission aus `docs/balance.md`).

## Grafikoptionen (umgesetzt, Compatibility-Renderer bleibt)
Esc-Menü, Reiter „Grafik“ (`PauseMenu._show_graphics`, `Settings` in `scripts/settings.gd`, gespeichert in `user://settings.cfg`): Voreinstellung (Niedrig/Mittel/Hoch), Anzeige (Fenster/Vollbild), V-Sync, Bildrate (30/60/120/unbegrenzt), Renderauflösung (50/75/100 %), Kantenglättung (Aus/FXAA/MSAA 2x/4x), Schatten (Aus bis Hoch), Leuchteffekt, Tiefenunschärfe (Tilt-Shift), Partikel und Regen. Entscheidung des Nutzers: **kein Wechsel auf Forward+**, kein Raytracing. Test: `tests/test_settings.gd`. Helligkeit und Kontrast sind im Reiter „Grafik“ (2026-11-09), die Lautstärke im Reiter „Ton und Spiel“.

### Aufgehoben: Wachturm der Frischlinge
Das Sprite `fx_wachturm` (Holzturm auf Stelzen mit Eberschädel-Banner) ist fertig, passte aber nicht in Mission 12. Für eine spätere Schweine-Mission oder ein Lager der Frischlinge nutzen (als `decor` mit `sprite: "fx_wachturm"`).

### Reserve für Mission 12: Stachelia greift in Runde 4 von hinten an (nur falls die Mission zu schwer ist)
Entscheidung des Nutzers: Wenn Mission 12 zu schwer ist, taucht in **Runde 4 Stachelia mit drei Bienen** auf und greift die Schweine **von hinten** (Ostufer) an. Sie kämpft **auf Seiten der Helden und wird vom Spieler gesteuert**, steht der Gruppe aber **ablehnend** gegenüber (Dialog mit spitzen Bemerkungen). Technik: `spawn`-Schritt mit `team: "p"` (gibt es schon) in einem `turn: 4`-Auslöser, Stachelia plus drei `bienenkrieger`, Dialog `left_expr`/`right_expr` auf misstrauisch. Zeitlich passt es zu Mission 11 (sie ist dort geflohen und hat Rache geschworen). **Messung (E13):** nicht nötig, die Mission ist laut Simulation leicht (100 % bei ×1,0 bis ×1,5, 86 bis 94 % bei ×1,75).

### Heldenstufen: ersetzt durch Talentpunkte (umgesetzt, `docs/fortschritt.md`)
Die festen Stufen wurden entfernt; die Gruppe steigt je Mission eine Stufe, alle drei Stufen gibt es einen Talentpunkt, verteilt nur für Helden der Gruppe (Aufstiegs-Bildschirm nach der Statistik, neue Helden vor der Mission) auf Leben, Angriff, Fähigkeit 1 und 2. Offen: neue Fähigkeiten beim Aufsteigen (zu groß), Balancing von Mission 11 bis 13 mit Talenten.

### Stachelia wird Heldin (ab Mission 14)
`bienenmaedchen` ist jetzt `hero: true` mit `from: 14`: wählbar ab der nächsten Mission nach dem Labor. Sie hat schon zwei Fähigkeiten (Giftstachel und Bienenkorb), also zwei Talentfelder. Offen: Mission 14 selbst, Dialog zum Beitritt (sie steht den Helden weiter ablehnend gegenüber), Heilhonig als dritte Idee nur falls gewünscht.

### Testlabor (umgesetzt, 2026-11-03)
Im Kapitelmenü (Hauptmenü, „brumm“ tippen) gibt es **„Testlabor“** (`TestLab`, `Main._lab_run`): **Arena** (gewählter Held gegen Gegner und zwei Büttel, auf Wunsch mit vollen Talenten und Ausrüstung Stufe 3), **Aufstiegsbildschirm**, **Lager** (Kapitel 8, 999 Gold), **Belohnungs- und Statistikbildschirm** und **Reisebild**. So lässt sich jede neue Fähigkeit oder jeder Bildschirm direkt ansehen, ohne Missionen zu spielen. Screenshot-Variante: `SHOT=lab SHOT_PART=arena|aufstieg|lager|belohnung|reise`.

### Gruppenwahl ohne Scrollen (2026-11-04)
Mit rund 14 wählbaren Helden lief die Auswahlliste über den Bildschirm. Die **Gruppenwahl** ist neu aufgebaut (`SquadSelect`): oben die Truppe als kompakte Karten (gewählter Platz hervorgehoben), darunter **immer sichtbar die Reservebank** als dichtes Raster (ganze Karte klickbar, Name zweizeilig, Rolle), breiteres Panel (1180 px). Ablauf: erst bei einem Platz „Tauschen“, dann auf einen Helden der Bank klicken. Passt bis etwa 20 Helden in zwei Reihen, darüber scrollt es weiter.

## Plottwist (später): Der Endboss ist in Wirklichkeit der Sack (notiert 2026-11-04)
**Der Händler „Sack“, der mit der Gruppe reist, ist der eigentliche Endboss.** Bisher nur Idee, nicht umgesetzt, und **geheim zu halten** (nicht in Trailern andeuten, im Spiel nur als dezenter Hinweis).
- **Wann gemeint:** „Regent besiegen“ heißt: **den letzten Level auf der Wüsteninsel bestehen (Mission 9, Festung)**. Das löst seine **Flucht** aus (vorhanden: Siegesgespräch „Der Regent gesteht“ = `triggers[5]` in `missions/ch9.json`, `victory` mit `spawn fuerst` und `retreat fuerst`). **Dort werden die Dialoge angepasst.**
- **Hinweis:** Der Regent sagt, bevor er flieht, dass er **Angst vor dem „blauen Ungetüm“** hat. Der **Hundsfreund fühlt sich angesprochen und beleidigt** (er ist blau), gemeint ist aber **der Sack**, der mit der Gruppe reist.
- **Geändert (2026-11-05): Der Hinweis in Mission 9 („blaues Ungetüm“, beleidigter Hundsfreund) wurde vom Nutzer wieder gestrichen.** Die Spur läuft jetzt über **Mission 14** (Bianca belauscht den Meister mit dem Regenten: „nur ein dunkler, blauer Schatten“) und **Mission 19** (der Regent hat ihn einmal im Schatten getroffen: „nur einen blauen Mantel oder Pelz“, der Hundsfreund knurrt „blau, was?“). Der Hundsfreund steht weiter in der Gruppe der Karte von Mission 9, ist dort aber nicht mehr fest. Ursprünglich (nicht mehr aktuell) war der Hinweis in Mission 9: Im Siegesgespräch sagt der Regent „… bringt bloß dieses blaue Ungetüm nicht näher!“, der **Hundsfreund** (blau wie der Sack, daher die **falsche Fährte** für den Spieler) fühlt sich beleidigt. Er ist deshalb in Mission 9 **zwingend dabei**: Er steht jetzt anstelle von Dr. Humbug in der Gruppe der Karte (`map_ch9.json`), und seine Zeilen tragen das Story-Flag (feste Figur). Test: `tests/test_festung.gd`. Der Sack bleibt als Bösewicht weiter ungenannt.
- Umsetzung später (Rest): Zeilen in `story_ch9.json`/`missions/ch9.json` (Regent + Hundsfreund, Story-Flag und Rückfallstimmen beachten), weitere dezente Hinweise in späteren Missionen, Kampf mit dem Sack als letzter Gegner. Vorher klären: Wie wird der Sack zum Gegner (Rolle des Meisters? Verrat?), und die Rolle des Händlers in Lager und Shop.
- Konflikt zum Meister-Plot (Professor Kugelblitz, „der Meister“ im Norden): Der Sack könnte der Meister sein oder dahinterstehen; mit dem Nutzer abstimmen, bevor Missionen 19+ geschrieben werden.

## Umgesetzt (2026-11-09): Filmische Kamerafahrt als Einleitung eines Levels (Missionsfeld `intro_flight`, siehe `docs/missionen.md`)
Im Trailer 5 (`game/scripts/trailer5.gd`, `_dusk_shot`, `_lab_shot`) gibt es **filmische Kamerafahrten mit flacherem Blickwinkel** (niedrige Kamera, geringes FOV, langsames Schieben/Schwenken über die Karte, mit Kinobalken). Das soll als **Einleitung einzelner Level** ins Spiel:
- **Wann:** Vor der Gruppenwahl oder dem Kampfbeginn (zum Beispiel nach der Einleitungs-Geschichte), pro Mission **optional** per Missionsfeld (zum Beispiel `"intro_flight": {"from": [...], "to": [...], "fov": 34, "height": 2.4, "seconds": 6}`), mit Rückfall auf die normale Karte. Überspringbar (Klick oder Esc), im Testlabor einzeln aufrufbar.
- **Bausteine zum Wiederverwenden:** die Kamerafahrt per Tween auf `b.cam` (Position und `look_at`, siehe `_dusk_shot`: `set_cam`-Callable mit `t` von 0 bis 1) und die Kinobalken (`_bars`, 92 Pixel oben und unten) aus Trailer 5; im Spiel als eigene Klasse (zum Beispiel `LevelFlyover`), die vor `Stage.start_battle` läuft und danach die normale Spielkamera wiederherstellt (`_enter_close_view` / Standardkamera).
- **Ideen je Mission:** Dorf bei Dämmerung (Mission 1), Hohlweg mit der Mauer (2), brennendes Dorf (3), Hafen und Steg (6), Festung am Berg (9), Labor mit dem Glasbehälter im Gewitter (13), Sumpf mit Nebel (15), Schneelandschaft bei Nacht (17).
- **Zu beachten:** UI nach jeder Änderung per Screenshot prüfen (1280×720), Kamerafahrt darf keine Figuren verdecken, die Gruppenwahl und der Spielstart bleiben danach unverändert.

## Proof of Concept: Zwischensequenz im Schneesturm (2026-11-04)
`game/scripts/snow_trek.gd` (`SnowTrek`): Die Gruppe (Mira, Albrecht, Hundsfreund, Wendy, Stachelia, Robo) stapft im Gänsemarsch einen Pass im Schnee-Biom hinauf, wie der Weg am Caradhras. **Alles in 3D mit den Chibi-Sprites** (ohne Animationsphasen: nur Stapf-Wippen, die Figuren stecken knietief im 3D-Schnee (ins Gelände versenkt, der Tiefentest verdeckt die Füße), Stachelia schwebt), **flache Kamera** mit Fahrt (erst seitlich, dann schräg von vorn, FOV 37 auf 31), Schneetreiben (zwei Partikelschichten, dicht und fast waagerecht), dunkle Sturmstimmung mit Vignette, Nebel, Windrauschen (synthetisch, nur gefiltertes Rauschen mit Böen, `assets/audio/wind_sturm.wav`), Windböen mit Kamerawackeln und weißem Schleier, Kinobalken, Titelkarte „Der Pass im Schneesturm“ (Kapitelzeile optional über `kicker`), Ein- und Ausblenden. Terrain aus Rauschen (Pass steigt an, Felswände), Schneefichten und Felsen als Sprites, dunkle ferne Felsmassive als Silhouetten. Klick überspringt.
- **Aufrufen:** Testlabor → „Zwischensequenz Schneesturm (PoC)“; Video: `SHOT=snowtrek godot --path game --write-movie out/trailer/snowtrek_raw.avi --fixed-fps 30` (fertig als `out/trailer/snowtrek.mp4`, 24 s); Standbild: `SHOT=snowtrek SHOT_DELAY=9 SHOT_OUT=<png>`.
- **Offen für den Einbau als echte Zwischensequenz** (zwischen zwei Missionen, zum Beispiel vor Mission 18): Missionsfeld `interlude_before`/`interlude_after` mit `scene: "snow"` (wie `sea` in `Interlude`), Gruppe aus der gewählten Truppe statt der festen Liste, Musik und Windgeräusch (bisher nur Whoosh), Spur im Schnee, mehr Abwechslung der Kulisse, Kamerafahrten zum Wiederverwenden für die Level-Einleitungen (siehe die Idee darüber).
