# Plan: 15 neue Fähigkeiten (aus den Notizen im Charaktere-Tab)

Quelle: `game/data/ability_notes.json` (zweites Feld je Figur). Ziel: jede Fähigkeit spielbar, mit eigener Grafik, Animation, Sound, Balancing und Test. Es soll „schick“ werden, also nicht nur Zahlen, sondern ein sichtbarer Auftritt je Fähigkeit.

## 1. Bestandsaufnahme (was es schon gibt)

- **Daten:** `abilities.json` (Ziel, Reichweite, Fläche, Abklingzeit, `effects`-Liste mit `damage`, `status`, `heal`, `splash`, `jump`, `throw`, `polymorph`), `fx.json` (Animationsparameter je Fähigkeit), `units.json` (`abilities`-Liste je Figur).
- **Ausführung:** `battle.gd` `_apply_effect`, Status in `status.gd` (stun, poison, taunt, stealth, buff, tired, scared, defend, wachsam).
- **Effekte:** `scripts/fx/fx.gd` und `fx_abilities.gd` haben fertige Bausteine: Projektil mit Bogen, Flächenwelle, Schockwelle, Strahl, Partikel, Kamerawackeln, Hitstop, Squash, Hop, Lunge, Knockback, Leuchten, Statussymbole an der Figur (`sync_status`). Neue Effekte sind also meist Zusammensetzen und neue Sprites, kein neuer Unterbau.
- **Sprites:** Gemini-Pipeline (`tools/gemini/run.mjs` mit `fx_*`-Aufträgen, `chroma_key.py fx`). Vorhanden und wiederverwendbar: `fx_arrow`, `fx_bubble`, `fx_foam`, `fx_smoke`, `fx_fireball`, `fx_star`, `fx_slash`, `fx_sweat`, `fx_exclaim`, `fx_bienenstock`, `fx_honig`, `fx_honigtopf`, `fx_bone`, `fx_claw`, `fx_cross`, `fx_leaf`, `fx_rune`, `fx_flower`.
- **Sound:** `tools/make_sfx.py` (prozedural) mit Ereignissen in `sfx.json`.
- **Simulator:** `game/sim/*` bildet Fähigkeiten nach. Neue Fähigkeiten müssen dort ebenfalls rein, sonst stimmt das Balancing nicht mehr.

## 2. Die 15 Fähigkeiten im Überblick

| Figur | Fähigkeit | Wirkung (so umgesetzt) | Neue Technik | Aufwand |
|---|---|---|---|---|
| Wendy | **Wollmantel** | Verbündeter (Reichweite 1–3): 2 Runden −50 % erlittener Schaden | Status `schild`, Hook in `Combat.damage` | S |
| Brumm | **Bärengebrüll** | Ein Gegner (Reichweite 1–2): 2 Runden eingeschüchtert, läuft weg | Status `scared` nutzen, Fluchtlogik in KI | M |
| Lin | **Stabwirbel** | Alle 8 Nachbarfelder (wie Todeswirbel), ohne Erschöpfung | nur Daten (`ring8`) | S |
| Elisabeth | **Arrr (Wutanfall)** | Selbst: 2 Runden ×2 Schaden, nicht steuerbar, greift zufällige Ziele an | Status `wut`, Auto-Aktion in der Spielerphase | L |
| Stachelia | **Verstärkung (Bienenkorb)** | Stellt Bienenkorb auf ein freies Feld in Reichweite 1–2; er bringt Bienenkrieger hervor | Beschwörung, Stock-Logik aus Mission 5 wiederverwenden | L |
| Brunhilde | **Prost** | Angrenzender Verbündeter bekommt Bier: Heilung 8 | nur Daten + Animation | S |
| Muskel-August | **Bearhug** | Angrenzender Gegner wird gequetscht: ×2,2 Schaden | Daten + Animation | S |
| Dekade | **Kyujutsu** | Bogenangriff, Reichweite 1–4, Schaden wie sein Nahkampfangriff (×1,0), der Gewinn ist nur die Reichweite | nur Daten (wie `knochenwurf`) | S |
| Oskar | **Brandbombe** | Reichweite 1–3, Treffer + Brennen 3 Runden (3 Schaden pro Runde) | Status `brennen` (analog Gift) | M |
| Maja | **Flucht** | Maja ist Gegnerin und entscheidet allein: bei ≤35 % Leben Rauch, springt zufällig an den Kartenrand, +20 % Leben | Auslöser in der Gegner-KI, Teleport | M |
| Dr. Humbug | **Tonikum** | Flasche, Reichweite 1–2, Fläche 1 um das Ziel: Verbündete +1 Bewegung (2 Runden), Gegner übel (−2 Bewegung, 2 Runden) | Status `tempo`/`uebel` mit Bewegungs-Modifikator, Ziel „Feld“ | L |
| Ninjas | **Hinterhältiger Angriff** | Nur von hinten: normale Gegner sofort tot (Büttel, Soldaten, Bienen), Namensträger ×1,5 | Blickrichtung je Figur, Feld-Markierung „von hinten“ | L |
| Hund | **Bellen** | Gegner im Umkreis 3: jeder mit 50 % Chance (mindestens einer) 2 Runden eingeschüchtert | `scared` nutzen, Zufallsauswahl | M |
| Magical Girl | **Sternschnuppe** | Kartenweite Reichweite, normaler Angriffsschaden (×1,0) | Reichweite 99, Himmels-Animation | S |

Aufwand: S = klein (Daten, Animation), M = mittel (neue Spielregel), L = groß (neue Mechanik mit Auswirkungen auf KI, Zielwahl, Simulator).

## 3. Unterbau, der mehrere Fähigkeiten braucht (Phase 0)

1. **Neue Status** in `status.gd` mit Namen, Gut/Schlecht-Kennung, Statussymbol (`fx.sync_status`): `schild`, `wut`, `brennen`, `tempo`, `uebel`. `scared` existiert; zu prüfen, wie die KI darauf reagiert (Gegner sollen vom Gegner weglaufen, nicht angreifen).
2. **Bewegungs-Modifikator:** `mods.move` in der Reichweitenberechnung von `battle.gd` (heute nur ATK/DEF). Gebraucht für `tempo` und `uebel`.
3. **Schadens-Hook:** `Combat.damage` berücksichtigt `schild` (×0,5).
4. **Blickrichtung:** Jede Figur merkt sich `u["face"]` (beim Bewegen, Angreifen, `_turn_towards`). Der Hinterhalt prüft, ob der Ninja auf dem Feld hinter dem Ziel steht.
5. **Zielart „Feld“** (Tonikum, Bienenkorb) und „nur gültige Felder“ (Hinterhalt): Die Zielmarkierung in `_begin_targeting` bekommt eine Feldliste statt Figurliste.
6. **Auto-Aktionen:** Eine Figur unter `wut` (Spielerseite) handelt selbständig. Dafür wird die vorhandene Gegner-KI für eine Figur aufgerufen (`_ai_act(u)`), mit Zufallsziel bei Wut. Majas Flucht läuft ohnehin in der Gegner-KI und braucht nur einen Auslöser (Leben ≤35 %, einmal pro Kampf).
7. **Beschwörung:** Neue Figur mitten im Kampf auf eigener Seite (Stock als Objekt mit Lebenspunkten, spawnt Bienenkrieger). Grafiken aus Mission 5 „Stachelias Rückkehr“ werden wiederverwendet: Bienenkrieger-Figur, `fx_bienenstock`, `fx_honig`. Die Spawn-Logik der Missionstrigger (`team`, `hp`, `guard`) und `HIVE_CAP` sind schon da.
8. **Fähigkeitsliste bei Figuren mit zwei Fähigkeiten:** UI-Button-Reihe prüfen (Albrecht und Robo haben schon zwei; Kapazität bis drei).
9. **Simulator:** `SimBattle` bekommt alle neuen Effekte (Status, Beschwörung, Rückzug), damit `tools/balance.py` weiter aussagekräftig bleibt.
10. **Editor:** Neuer Knopf „In abilities.json übernehmen“ ist nicht nötig; stattdessen werden die Notiztexte beim Umsetzen zu den echten Fähigkeitstexten, die Notizfelder bleiben als Entwurfsblock für weitere Ideen.

## 4. Grafik und Animation je Fähigkeit

Alle Animationen werden aus den vorhandenen Bausteinen von `fx.gd` zusammengesetzt, also Tweens, Partikel und Billboard-Sprites, passend zum jetzigen Stil. Neue Sprites kommen per Gemini (`fx_*`, grüner/schwarzer Hintergrund, `chroma_key.py fx`).

| Fähigkeit | Ablauf (Animation) | Neue Sprites |
|---|---|---|
| **Wollmantel** | Wendy hüpft, wirft den Mantel im Bogen; er landet auf dem Ziel, Wolle-Puff mit Flusen, Ziel hat danach eine leicht flauschige Hülle (Statussymbol: weiße Wolke). | `fx_wolle` (Mantel im Flug), `fx_wolke_schild` (Hülle), `st_schild` (Symbol) |
| **Bärengebrüll** | Brumm richtet sich auf (Squash nach oben), Kamerawackeln, drei expandierende Schockringe, Gegner weicht zurück (Knockback), Schweißtropfen, rennt dann beim Fliehen weg. | `fx_bruell` (Schallwellen-Maul), `st_angst` (vorhanden `fx_sweat` nutzen) |
| **Stabwirbel** | Wie Todeswirbel, aber mit Stab: Stab-Sprite kreist zwei Mal um Lin, Hiebe an den acht Feldern mit Funken. | `fx_stab` |
| **Wutanfall** | Lauter Aufschrei, Figur wird rot getönt, Dampfwolken aus den Ohren (Partikel), Wut-Ader als Symbol, zittert (Squash-Pulse). Beim Automodus: Angriffe mit größerem Hitstop und Funken. | `fx_dampf`, `fx_wutader`, `st_wut` |
| **Bienenkorb** | Stachelia stellt den Korb ab: Korb fällt vom Himmel mit Staubring, Bienenwolke summt heraus (Partikel, gelb), nach jedem Zug kommt ein Bienenkrieger heraus (Spawn mit Pop). | keine neuen: `fx_bienenstock`, `fx_honig` und Bienenkrieger-Figur aus Mission 5 |
| **Prost** | Brunhilde schiebt einen Krug über den Boden (Gleiten) oder wirft ihn sanft; Schaum spritzt, Ziel trinkt (Squash), goldene Heilpartikel und „+8“. | `fx_bierkrug` (`fx_foam` vorhanden) |
| **Bearhug** | Muskel-August schnappt zu: Ziel wird zu ihm gezogen (Tween), beide wackeln, Knackgeräusch, Comic-Sterne und Wort „KRACK“, Ziel fällt nach hinten. Hitstop lang. | `fx_krack` (Comic-Schriftzug) |
| **Kyujutsu** | Dekade zieht den Bogen (Lehne zurück, Pfeil glüht auf), Pfeil fliegt in flacher Kurve mit Wind-Streifen, Treffer mit Funken; Nahkampf: kurzer Schlag mit dem Bogen. | `fx_pfeil_gross` (hat `fx_arrow`), `fx_windstreifen` |
| **Brandbombe** | Oskar zündet die Lunte (Funken), wirft die Bombe im hohen Bogen; Explosion mit Feuerball und Funken, Ziel brennt mit loderndem Symbol, Rauchfaden. Brennschaden pro Runde als orangene Zahl. | `fx_bombe`, `fx_flamme` (auch als Statussymbol) |
| **Flucht** | Maja wirft Rauchkugel: Rauchwolke, Figur verschwindet (Fade), Rauch am Zielfeld, erscheint dort mit Pop, Heilpartikel. | Rauch vorhanden, `fx_rauchkugel` |
| **Tonikum** | Humbug wirft Flasche im Bogen; Glas zerbirst, grüner/lila Dunst, Blubberblasen steigen auf (`fx_bubble`, grün getönt) im Kreis. Verbündete bekommen Flügelschuh-Symbol, Gegner einen grünen Totenkopf-Kopf. | `fx_flasche`, `st_tempo`, `st_uebel` |
| **Hinterhalt** | Bildschirm kurz abgedunkelt, Ninja verschwindet im Schatten, Nachbild-Schweif springt zum Ziel, X-förmiger Hieb (`fx_slash`), Ziel zerfällt in Rauch (bei normalen Gegnern). | `fx_schatten` (Nachbild), `fx_hieb_x` |
| **Bellen** | Hund springt, „WUFF!“-Sprechblase, drei Schallringe, Gegner im Umkreis zucken zusammen; die getroffenen zittern und tragen Angst-Symbol. | `fx_wuff` |
| **Sternschnuppe** | Funkelnder Stern fällt diagonal vom Himmel mit Schweif aus Partikeln, Einschlag mit Schockring, rosa Leuchten, kleine Sterne regnen. | `fx_sternschnuppe`, `fx_schweif` |

Neue Gemini-Sprites insgesamt etwa 17, davon 6 Statussymbole (klein, einheitlich). Die Symbole bekommen eine gemeinsame Stilvorlage (Rand, Größe), damit sie neben den bestehenden wie `st_*` aussehen.

**Optionale Aufwertung („Schick-Stufe“):** ein kleiner Flipbook-Helfer in `fx.gd` für 4-Bild-Sprites (Flammen, Schweif, Bienenschwarm), im Gemini-Auftrag als 2×2-Raster erzeugen und in Frames zerlegen. Ohne Flipbook gehen alle Effekte auch mit statischen Sprites plus Tweens, wie die bisherigen Fähigkeiten.

## 5. Sound

Jede Fähigkeit bekommt einen Ereignis-Eintrag in `sfx.json` und eine Funktion in `tools/make_sfx.py`: Wollmantel (Pomp, weich), Gebrüll (tiefes Röhren + Rauschen), Stabwirbel (Wusch), Wutanfall (Kreischen, Dampf), Bienenkorb (Brummen), Prost (Krug auf Holz, Schluck), Bearhug (Knacken), Kyujutsu (Sehne, Zischen), Brandbombe (Lunte, Boom), Flucht (Puff), Tonikum (Glas, Blubbern), Hinterhalt (Schnitt), Bellen (Wuff), Sternschnuppe (Pfeifen, Glöckchen). Test im Soundlabor.

## 6. Balancing

**Gemeinsame Abklingzeit (beschlossen):** Alle Fähigkeiten einer Figur teilen sich eine Abklingzeit. Wer eine Fähigkeit nutzt, sperrt damit auch die zweite, und zwar für die Abklingzeit der benutzten Fähigkeit. Das bremst den Zuwachs stark: Die Figur kann nicht öfter einen Spezialeffekt auslösen als bisher, sie hat nur die Wahl. Der Zugewinn ist Flexibilität (Heilen oder Schlagen, je nach Lage) und Spezialfälle (Hinterhalt, Sternschnuppe für weit entfernte Ziele).
Folgen, die ich prüfe: Ser Albrecht (Schlachtruf und Verspotten, je 4) und Robo (Laser 3, Heilstrahl 2) hatten bisher getrennte Abklingzeiten und werden dadurch schwächer; die Missionen mit ihnen laufen durch den Simulator, ggf. wird die Abklingzeit gesenkt. Umsetzung klein: Überall, wo `u["cd"][id]` gesetzt wird (`battle.gd` dreimal, `sim_battle.gd` zweimal), wird der Wert für alle Fähigkeits-IDs der Figur gesetzt.

- Mit allen neuen Fähigkeiten sind die Helden deutlich stärker. Der Simulator (`tools/balance.py`) zeigt die Siegquoten je Mission; Ziel bleibt wie bisher: ×1,0 ≈ 100 %, ×1,5–1,75 ≈ 50–60 %. Bei Bedarf werden Gegner stärker (HP, Anzahl) oder Fähigkeiten länger abgeklungen.
- Größte Risiken: **Hinterhalt** (Sofortkill), **Bienenkorb** (wächst lawinenartig → Deckel von 3 Bienen aktiv, Korb hält 3 Runden oder hat 10 Leben), **Sternschnuppe** (kartenweit → Schaden nur ×1,0 und Abklingzeit 3), **Wut** (Zufallsschaden gegen Freund und Feind).
- Vorgeschlagene Abklingzeiten: Wollmantel 3, Gebrüll 4, Stabwirbel 3, Wut 6, Bienenkorb 6, Prost 3, Bearhug 4, Kyujutsu 2, Brandbombe 3, Flucht 8 (einmal pro Kampf), Tonikum 4, Hinterhalt 4, Bellen 4, Sternschnuppe 3.

## 7. Reihenfolge der Umsetzung

1. **Phase A (parallel, sofort):** Gemini-Aufträge für alle neuen Sprites starten (läuft im Hintergrund) und Soundskizzen in `make_sfx.py`.
2. **Phase B – Unterbau:** Status, Bewegungs-Modifikator, Schadens-Hook, Blickrichtung, Feldzielart, Auto-Aktion (Abschnitt 3).
3. **Phase C – einfache Fähigkeiten (S):** Wollmantel, Stabwirbel, Prost, Bearhug, Kyujutsu, Sternschnuppe. Je Fähigkeit Daten, Animation, Test.
4. **Phase D – mittlere (M):** Bärengebrüll, Bellen, Brandbombe, Flucht.
5. **Phase E – große (L):** Tonikum, Wutanfall, Hinterhalt, Bienenkorb.
6. **Phase F – Politur:** Sound einbinden, Statussymbole, Fähigkeitsbeschreibung im Lager, Kampfstatistik („Fähigkeiten genutzt“ zählt automatisch mit), Trailer-Szenen optional.
7. **Phase G – Balancing:** Simulator erweitern, Läufe je Mission, Anpassung Gegner und Abklingzeiten, Doku `docs/balance.md` und `docs/figuren.md`, Backlog aktualisieren.
8. Nach jeder Phase: alle Headless-Tests, Screenshot-Modus je neue Fähigkeit (`SHOT=ability`-Modus, ggf. neu), Commit und Push.

## 8. Annahmen, die ich getroffen habe (bitte korrigieren, falls anders gemeint)

1. **Alle Figuren haben ihre neue Fähigkeit sofort** (bestätigt).
2. **Elisabeth in Wut:** Zufallsziel können auch Verbündete sein (bestätigt).
3. **Maja:** Gegnerin, entscheidet allein (bestätigt). Die Nemesis-Flucht in den Missionen bleibt unberührt.
4. **Kyujutsu:** Bogenangriff mit dem Schaden von Dekades Nahkampfangriff, nur mit Reichweite 1–4 (korrigiert).
5. **Hinterhalt** zählt als normal: Soldaten, Büttel, Bienenkrieger, Dummy. Namensträger und Bosse nehmen ×1,5 Schaden (bestätigt).
6. **Brandbombe** setzt keine Häuser in Brand, nur Brennen auf Figuren (bestätigt).
7. **Stachelia** bekommt den Bienenkorb zusätzlich zum Giftstachel. Ob sie später dem Team beitritt, bleibt ein eigener Backlog-Punkt.
8. **Notizen:** „Lin … quasi wie Takeda“ ist nur eine Referenz auf den Wirbel der Samurai-Figur, kein neuer Charakter.

## 9. Offene Entscheidungen für dich

- Alle Annahmen sind bestätigt bzw. korrigiert.
- Soll die Schick-Stufe mit Flipbook-Animationen gleich mitkommen (mehr Gemini-Arbeit, schöneres Ergebnis) oder erst nach Phase G?


## 10. Stand der Umsetzung (2026-11-01)

Alle 14 Fähigkeiten sind im Spiel (`abilities.json`, `units.json`), mit Animation (`scripts/fx/fx_new.gd`), Sound (`make_sfx.py`, `sfx.json`) und Test (`tests/test_new_abilities.gd`). Abweichungen und Besonderheiten gegenüber dem Plan:

- **Gemeinsame Abklingzeit:** `Items.start_cooldown`. Ausgenommen (`"solo": true`) sind die schon vorhandenen Paare Schlachtruf/Verspotten (Albrecht), Roter/Grüner Laser (Robo), Stabsprung (Lin, freie Aktion) und Majas Flucht. Ohne diese Ausnahmen wäre Mission 3 bei ×1,6 von 18 % auf 7 % gefallen.
- **Panik statt Angst:** „scared“ ist schon der Status von Majas Eisigem Blick (−3 ATK, −1 DEF). Brumm und der Hund setzen daher den neuen Status `angst` („Panik“, Gegner laufen weg und greifen nicht an).
- **Bienenkorb** ist ein Weltobjekt (`hive_p` in `objects.json`), kein eigener Figurentyp: schlüpft alle 2 Runden einen Bienenkrieger (höchstens 3), löst sich nach 6 Runden auf (`Battle._player_hive_phase`).
- **Wutanfall:** Status `wut` dauert 3 Phasen (= zwei Runden Kontrollverlust); die Figur handelt am Phasenanfang selbst (`_rage_phase`), Zufallsziel auch unter Freunden.
- **Tonikum und Bienenkorb** haben die neue Zielart `tile` (Feldwahl mit Flächenvorschau).
- **Hinterhalt** prüft die Blickrichtung (`u["dir"]`); Ziele „normal“ sind Figuren mit Marke `standard` oder `schwarm`.
- **Simulator:** kennt Hinterhalt, Panik, Brennen, Wollmantel und die Flächenwirkungen; Bienenkorb, Tonikum, Wutanfall und Majas Flucht bleiben unmodelliert (der Simulator unterschätzt die Helden dort leicht).
- **Messung (Simulator, 450 Kämpfe je Zelle):** Mission 3 ×1,6: 18 % → 17 %; Mission 5 ×2,0: 31 % → 70 %; Mission 6 ×1,5: 93 % → 93 %; Mission 7 ×1,25 (neue Heiler): 86 % → 78 %. Die Missionen auf ×1,0 bleiben bei 100 %.
- **Sprites:** 15 neue `fx_*` (Wolle, Gebrüll, Stab, Dampf, Zornader, Krug, Krack, Bombe, Flamme, Flasche, Wuff, Sternschnuppe, Rauchkugel, Flügelschuh, Übel). Die Zornader ist ein einzelner Bogen, die Marke setzt `_anger_mark` aus vier Stücken zusammen.
- **Noch offen:** Flipbook-Animationen (Schick-Stufe), Statussymbole im Info-Feld der Figurenkarte, Feinabstimmung der Abklingzeiten nach dem Probespielen, Mission-Balance (Mission 5 ist mit den neuen Fähigkeiten etwas leichter).
