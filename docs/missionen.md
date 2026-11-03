# Missionen: Fähigkeiten als Werkzeuge

## Grundidee
Heute heißt jede Mission „besiege alle Gegner“. Neu: **Die Karte stellt Probleme, die Fähigkeiten lösen.** Dieselben 15 Spezialfähigkeiten, die im Kampf wirken, wirken auch auf Dinge der Welt: Mauern, Tore, Feuer, Brücken, Schalter, Wachen. Es gibt dafür **kein neues Menü**: Die Fähigkeit im normalen Fähigkeiten-Menü wird einfach auch auf einem Hindernis einsetzbar (goldene Markierung, Vorschau „Brunhilde löscht das Feuer“).

Daraus folgt, was den Reiz ausmacht:
- **Die Heldenwahl vor der Mission zählt.** Das Lager (Reiter „Aufstellung“) wird zur Vorbereitung: Das Briefing zeigt Symbole der Hindernisse, und der Spieler wählt, wer mitkommt.
- **Mehrere Lösungen pro Hindernis.** Das belohnt Neugier und Wiederspielen und verhindert Sackgassen.
- **Fähigkeiten kosten wieder Aktion und Abklingzeit.** Wer das Tor sprengt, greift nicht an. Das macht Zeitdruck spannend.
- **Humor:** Die Lösungen sind die Charaktere (Bier löscht Feuer, Muskelaugust wirft Mira über die Mauer).

## Deine Beispiele, ausgearbeitet

**Das Dorf brennt.** Feuerfelder breiten sich nach jeder Gegnerphase auf angrenzende brennbare Felder aus (Wald, Dorf), vollkommen vorhersagbar, die Vorschau zeigt das nächste Feld. Dorfbewohner in brennenden Häusern verlieren pro Runde Leben.
- **Brunhilde, Fasswurf:** Das Fass voll Bier löscht ein 3×3-Feld (wie die Fläche der Gruppenheilung).
- **Gegenstand Bier:** löscht ein Feld (die gebraute Variante zahlt sich aus).
- **Wasser:** Feuer löscht von selbst neben dem See, ein Held in der Kette aus Eimern ist Albrechts Schlachtruf („Eimerkette“).
- **Todeswirbel (Takeda):** schlägt eine Schneise (Feuerschutzstreifen), das Feuer springt nicht darüber.
- Zeitdruck: Die Gegner greifen währenddessen an.

**Die Mauer mit Tor.**
- **Meister Lin, Stabsprung:** springt über die Mauer (es gibt schon Landefeld-Prüfung) und erreicht den Schalter.
- **Muskelaugust, Wurf auf einen Verbündeten:** Wurf wird auch auf Freunde erlaubt, ohne Schaden und ohne Betäubung, sie landen bis 4 Felder weit. Mira kommt so über die Mauer. Komisch und glaubwürdig.
- **Käpt’n Elisabeth, Kanone:** sprengt ein Loch. Laut, ohne Schalter, aber die Wachen kommen.
- **Robo, roter Laser:** schmilzt das Schloss.
- **Kage-Schwestern, Versteck:** schleichen durch die Wachen zum Seiteneingang.
- **Stachelia, fliegt:** kommt über die Mauer.
- Der Schalter dahinter öffnet das Tor für alle anderen.

## Katalog: was kann jede Figur außerhalb des Kampfes?
Jede Fähigkeit bekommt **Fähigkeitsmarken (caps)** in `abilities.json`. Hindernisse verlangen eine Marke.

| Marke | Wer | Wofür |
|---|---|---|
| `smash` | Bärenpranke (Mira), Wurf (Muskelaugust) | Barrikaden, Geröll, Türen aufbrechen |
| `blast` | Kanone (Elisabeth) | Tore, Mauern, Türme, Belagerungswaffen zerstören; laut |
| `melt` | Roter Laser (Robo) | Schlösser, Ketten, Eis, Gitter, Netze |
| `cut` | Todeswirbel (Takeda) | Hecken, Seile, Netze, Ranken, Feuerschneise |
| `leap` | Stabsprung (Lin), Stachelia fliegt | Mauern, Gräben, Schluchten |
| `throw_ally` | Wurf (Muskelaugust) | Verbündete über Hindernisse |
| `extinguish` | Fasswurf (Brunhilde), Bier | Feuer löschen |
| `sneak` | Versteck (Kage), Rauchbombe | Wachen passieren, Schlüssel stehlen |
| `lure` | Verspotten (Albrecht), Bärenpranke | Wachen/Gegner von einem Ort weglocken |
| `rally` | Schlachtruf (Albrecht) | Dorfmiliz überzeugen, Eimerkette, Moral |
| `heal` | Heilung, Gruppenheilung, Grüner Laser | verwundete Dorfbewohner, Vergiftete, Wiederbeleben |
| `transform` | Polymorph (Claude) | Wache in Frosch verwandeln, selbst als Frosch durch enge Löcher (nur Gegner/Normale) |
| `ranged_hit` | Knochenwurf (Hund), Kanone | fernen Schalter treffen |
| `poison` | Giftstachel (Stachelia) | Bienenstock-Missionen, Wachhund einschläfern, Brunnen vergiften (Gegner-Nachschub) |
| `magic` | Claude (Magier), Äther | Magische Siegel und Runen öffnen |

Dazu **Weitere Möglichkeiten**: Brumm (Bär) schiebt Felsen, Wendy beruhigt Schafe und Tiere (Humor), Robo lädt einen Kristallgenerator auf.

## Hindernisse (Objekte auf der Karte)
Datei `data/objects.json`: Typ, Aussehen, blockiert Bewegung/Sicht, **Lösungen** (Marke → Wirkung).

| Objekt | Blockiert | Lösungen |
|---|---|---|
| Mauer | Bewegung | `leap`, `throw_ally`, `blast` (Loch), Flieger |
| Tor (zu) | Bewegung | Schalter, `blast`, `melt`, `smash`, `sneak` zum Seitentor |
| Schalter | – | betreten (Held), `ranged_hit`, später Rätselkombination |
| Barrikade / Geröll | Bewegung | `smash`, `blast`, `cut` (Holz) |
| Feuer | brennt, schadet | `extinguish`, Schneise `cut`, brennt nach 3 Runden von selbst aus (außer Nachschub) |
| Hecke / Ranken / Netz | Bewegung | `cut`, `melt` |
| gebrochene Brücke | Bewegung | `leap` (Lücke ≤ 2), Flieger, `transform` (Frosch springt), `cut` (Baum fällen als Brücke), Floß |
| Wachposten (Sichtfeld) | Entdeckung | `sneak`, `lure`, `transform`, Hinterhalt (Rücken) |
| Magisches Siegel | Bewegung | `magic`, `melt` (kaputt) |
| Bienenstock | spawnt Bienen | `melt` (verbrennen), `poison`, `blast` |
| Verwundeter Dorfbewohner | Rettung | `heal`, Heiltrank |
| Dorfmiliz (schläft) | – | `rally` weckt sie als Verbündete |

Regeln:
- **Immer mindestens zwei Lösungen,** und mindestens eine ohne Spezialisten: Gegenstände (Rauchbombe, Äther, Gold) oder Kampf. So kann keine Gruppe festhängen.
- Nach jeder Lösung bleibt die Welt verändert (Loch in der Mauer, Brücke aus Baum).
- **Laut oder leise:** `blast` weckt Wachen, `sneak` nicht. Eine Entscheidung, keine Zahl.

## Missionstypen und Spannung
1. **Rettung gegen die Zeit** (Feuer, Verwundete).
2. **Hindernislauf** (Mauer, Tor, Schalter).
3. **Eskorte** (Dorfbewohner oder Karren; Gegner jagen sie; `lure` zieht Verfolger ab).
4. **Schleichen** (Sichtfelder anzeigen, entdeckt werden löst Verstärkung aus, kein Game Over).
5. **Halten** (Wellen, Fallen, Truhen als Vorbereitung).
6. **Zerstören** (Bienenstock, Belagerungswaffe; Schwächen mit `melt`/`blast`).
7. **Lebender Schützling** (verwundeter Drache: dauerhaft heilen, während man kämpft).
8. **Boss mit Umgebung** (Regent: Kristallschilde brechen mit `melt`, Vorbereitung entscheidet).

Spannung kommt von: sichtbarem Zeitplan („Runde 3: Verstärkung erscheint“), Entscheidungen zwischen laut und leise, Bonuszielen (Dorf gerettet, ohne Entdeckung, in N Runden) und davon, dass das **Briefing Hinweise gibt**, aber nicht alles verrät.

## Missionstyp „Lebender Schützling“: der verwundete Drache
Ein großer, verwundeter Drache liegt auf der Karte, die Bösen wollen an ihn heran. Er verliert **jede Runde Leben** (Blutung), die Gruppe muss die Angreifer besiegen **und** ihn dauerhaft hochheilen.

- **Der Drache** ist ein nicht steuerbarer Verbündeter, belegt 2×2 Felder, hat viel Leben (z. B. 120) und verliert zu Beginn der Gegnerphase einen festen Wert (z. B. 6 % seines Lebens). Fällt er auf 0, ist die Mission verloren. Die Blutung ist sichtbar angezeigt („−8 pro Runde“), nichts ist zufällig.
- **Heilquellen konkurrieren mit dem Kampf:** Wendys Heilung und Gruppenheilung, Robos grüner Laser, Heiltränke, später der Priester. Jede Heilung kostet die Aktion einer Figur, die dann nicht kämpft. Die Spannung liegt in der Aufteilung: wie viele Helden schützen, wie viele heilen?
- **Gegner zielen auf den Drachen:** Bogenschützen und Reiter bevorzugen ihn, Verspotten und Bärenpranke ziehen sie weg, Mauern und Barrikaden schirmen ihn ab. So kommen die Fähigkeiten aus dem Katalog (`lure`, `heal`, `smash`) zum Einsatz.
- **Der Drache wirkt zurück:** Ab 50 % Leben speit er einmal Feuer auf die Angreifer (Fläche, feste Wirkung), ab 100 % hebt er ab und beendet die Mission vorzeitig mit Bonus. So lohnt es sich, aggressiv zu heilen, statt nur knapp über 0 zu halten.
- **Belohnung/Geschichte:** Er wird ein Verbündeter (Kampf- oder Flugtier später) oder schenkt einen Gegenstand (Drachenschuppe als Talisman). Das passt zum Sammelgedanken.
- **Balancing:** Die Blutung wird aus der Heilkraft gerechnet. Der Lösbarkeits-Prüfer prüft, dass jede Gruppe mit mindestens einer Heilquelle (Figur oder Tränke) die Blutung ausgleichen kann; ohne Heiler braucht sie Heiltränke aus dem Lager. So gibt es nie eine unlösbare Gruppe.
- **Technisch:** `World` bekommt Objektart „Schützling“ (Leben, Blutung, Größe, Reaktionen) und Auslöser auf Lebensschwellen. Das Bild des Drachen (Porträt, Karten-Token) bestelle ich bei Gemini.

## Missionsliste (Entwurf, erster Handlungsbogen)
| # | Titel | Typ | Hauptidee |
|--:|---|---|---|
| 1 | Eichenfurt in Gefahr | Verteidigung | Büttel vor dem Dorf zurückschlagen, Dorf besuchen, Truhen, erster Kampf. Lehrt Bewegung und Angriff. |
| 2 | Der Hohlweg | Hindernislauf | Mauer und Tor, fünf Lösungen, Schalter. |
| 3 | Die gebrochene Brücke | Hindernislauf | Fluss: fliegen, Frosch, Baum fällen, Wurf. |
| 4 | Das Lager des Hauptmanns | Schleichen | Wachen mit Sichtfeld, Polymorph, Versteck, Verspotten. |
| 5 | Geleit der Flüchtlinge | Eskorte | Verfolger weglocken, Miliz wecken (Rally). |
| 6 | Der Bienenstock | Zerstören | Stachelia (Boss-Gegner), Stöcke verbrennen, Gift und Heilung. |
| 7 | Der verwundete Drache | Lebender Schützling | Drachen halten und dauerhaft heilen, Angreifer abwehren, Heilung gegen Kampf abwägen. |
| 8 | Die Belagerung | Hindernislauf + Kampf | Burgtor: Kanone, Wurf über die Mauer, Schalter, Zugbrücke. |
| 9 | Regent Morgrim | Boss | Kristallschilde, Umgebung, alle Marken im Einsatz, vielleicht hilft der Drache. |

Stachelia ist laut deinen Notizen General des Bosses. Die Bienen-Mission kann sie zum Gegner machen und später rekrutieren (Gift, Heilung als Auflösung).

## Dialoge mitten im Kampf
Nutzt das bestehende Dialogsystem über der Karte: Auslöser sind Betreten eines Feldes, Runde N, Objekt gelöst oder Held fällt. Beispiel Mission 1: Dorfbewohnerin ruft „Mein Haus!“, Brunhilde antwortet „Ich hab was zu trinken mitgebracht.“ Fähigkeiten-Einsatz an Hindernissen löst kurze **Reaktionszeilen** aus (mit lachend/wütend-Porträts), das gibt Charakter ohne große Szenen.

## Umsetzung (technisch)
**Daten**
- `data/missions/<id>.json`: Karte, Aufstellungsfelder, Gegner, Objekte, Auslöser, Ziele (Pflicht und Bonus), Belohnung, Briefingtext, Dialoge. Bestehende `map_ch1.json` wird zur ersten Mission.
- `data/objects.json`: Objekttypen mit Lösungen. `abilities.json` bekommt `caps` je Fähigkeit.

**Code**
- Neu `scripts/world.gd` (reine Logik, testbar): Objektzustände, `can_interact(unit, ability, tile)`, `apply(...)`, Feuerausbreitung (`tick_hazards`), Sichtfelder der Wachen, Auslöser.
- `grid.gd`: Objekte blockieren Bewegung und Sicht; Brücke/Loch schalten Felder frei; `leap` und Flug prüfen Landefelder.
- `battle.gd`: Fähigkeiten-Menü bietet Hindernisse als Ziele an, Vorschau, Objekt-Animationen (Mauerloch, Tor schwingt auf, Feuer löscht, Brücke fällt) über das vorhandene `Fx`.
- Neue Zieltypen: `Wurf` auf Verbündete (ohne Schaden), Fähigkeiten auf Objekte.
- Missionssteuerung (`mission.gd`): Ziele, Auslöser, Gewinn/Verlust (z. B. Dorfbewohner gestorben), Fortschrittsanzeige oben (Ziel, Runde, Gefahr).
- `Camp`: Reiter **Aufstellung** wird zur Heldenwahl mit **Briefing** (Hindernis-Symbole, empfohlene Marken).
- 3D-Objekte aus dem Mesh-Baukasten (`MeshKit`): Mauer, Tor, Schalter, Geröll, Brücke, Feuer (Partikel), Wachturm, Siegel.

**Simulation und Balancing**
- **Lösbarkeits-Prüfer** (`test_missions.gd`): für jede Mission und jede mögliche 6er-Gruppe prüfen, ob jedes Hindernis mindestens eine Lösung hat (Marken der Gruppe plus Gegenstände). Meldet, welche Gruppen festhängen würden. Das ist der wichtigste Test.
- Simulator bekommt Objekte und die KI einfache Ziele („Hindernis lösen, wenn der Weg dahinter zum Ziel führt“), damit Zeitdruck und Fähigkeitswerte gemessen werden können (wie oft gewinnt eine Gruppe ohne den Spezialisten?).

## Umsetzungsreihenfolge
1. **Mission als Datenformat** (Objekte, Ziele, Auslöser), `map_ch1` migrieren. Anzeige Ziel/Runde.
2. **Interaktion:** Marken, Objekte, Fähigkeiten auf Objekte, Wurf auf Verbündete. Zuerst nur Mauer, Tor, Schalter (Mission 2 spielbar).
3. **Feuer und Rettung** (Mission 1): Ausbreitung, Löschen, Dorfbewohner.
4. **Briefing und Heldenwahl** im Lager.
5. **Wachen und Sichtfelder** (Mission 4), **Eskorte** (5).
6. **Bienenstock** (6), **Drache** (7, braucht Objektart „Schützling“ mit Blutung und Gegner-Zielwahl), **Belagerung** (8), **Boss** (9).
7. Lösbarkeits-Prüfer und Balancing-Läufe (laufend mit jedem Schritt).

## Entscheidungen (getroffen)
- **Scheitern:** Pflichtziel verloren heißt erneut versuchen, Bonusziel verloren heißt die Geschichte geht weiter.
- **Gruppengröße:** noch offen, vorerst 6 Helden (bisheriger Stand), wird mit mehr Rekruten neu entschieden.
- **Rätsel:** Es bleibt ein **Strategiespiel**. Interaktive Aktionen sind in jeder Mission nur **Auflockerung und Würze**, keine Rätsel mit mehreren Schaltern, nie der Hauptinhalt.
- **Lärm und Verstärkung:** Verstärkung ja, aber **fest geskriptet** und nur, wenn es zur Mission passt (keine automatische Lärmregel).
- **Rekruten:** Stachelia ist anfangs Gegner und wird später Teil des Teams, ihr Charakter bleibt garstig. Gelöste Missionen schalten Rekruten frei.

## Umsetzungsstand
- **Schritt 1 fertig:** Missionsformat (`data/missions/ch1.json`, `scripts/mission.gd`) mit Zielen (besiege alle, halte N Runden durch, erreiche ein Feld), Niederlage bei gefallenen Helden, Auslösern (Runde N, Feld betreten) für Verstärkung, Popups und **Dialoge mitten im Kampf**, Zielanzeige im HUD, Test `tests/test_mission.gd`.
- Kapitel 1 hat einen Auslöser: Runde 3 erscheint ein Büttel als Verstärkung, mit kurzem Dialog.
- **Schritt 2 fertig:** Weltobjekte (`data/objects.json`, `scripts/world.gd`): Mauer, Tor, Schalter. Fähigkeiten bekommen Marken (`caps` in `abilities.json`) und wirken über das normale Fähigkeiten-Menü auf Objekte: Kanone sprengt Mauer und Tor, Laser schmilzt das Tor (nur auf gerader Linie), Pranke bricht das Tor, Stabsprung springt über Mauer/Tor, Knochenwurf trifft den Schalter, **Wurf wirft Verbündete** (Landefeld frei wählbar, bis 4 Felder). Flieger kommen über alles. Normale Angriffe können das Tor aufbrechen (Sicherheitsnetz, damit nie eine Gruppe festhängt). Auslöser reagieren auf Objektzustände (Tor offen/zerstört).
- **Mission 2 „Der Hohlweg“** (Mauer waagerecht quer über das Feld, Helden unten, Gegner oben, Tor in der Mitte; wer hinter dem Tor ankommt, öffnet es von innen automatisch mit einer Dialogzeile) (`data/missions/ch2.json`, `map_ch2.json`, `story_ch2.json`) ist spielbar, das Spiel läuft jetzt über zwei Kapitel mit Lager dazwischen. Tests: `test_world.gd`, `test_objects.gd`.
- Nächster Schritt: Feuer und Rettung (Mission 1 nachrüsten), danach Briefing und Heldenwahl.

- **Mission 3 „Mühlbach in Flammen“** (`data/missions/ch3.json`, `map_ch3.json`, `story_ch3.json`): Feuer als Weltobjekt (`fire`, `house`; `World.tick_fire`, 3 Phasen Brenndauer, Ausbreitung nur auf Häuser und Wald). Löschen: **Fasswurf** (Brunhilde, Umkreis 1) oder **„Feuer löschen“** (jede Figur, 1 Feld, Sicherheitsnetz). Brandschaden 4 auf Feuerfeldern, Vorschau der nächsten Zündung (orange Felder), Bonusziel „Kein Haus brennt ab“. Test: `tests/test_fire.gd`. **Offen:** Bier als Löschmittel (Gegenstand) und Feuer im Simulator (Balancing nicht gemessen).


## Feste Gruppen und Ereignisse (Entscheidung des Nutzers)
- **Keine Heldenwahl.** Jede Mission hat eine **feste Gruppe** (`players` in der Karte). Das ermöglicht Dialoge und Ereignisse zwischen genau diesen Figuren. Das Lager zeigt die Gruppe der **nächsten** Mission (Reiter „Aufstellung“ ist nur eine Anzeige), Ausrüstung und Rucksack bleiben frei verteilbar.
- **Mehr Ereignisse:** Verstärkung (geskriptet), Dialoge zwischen Figuren untereinander und mit Gegnern, Reaktionen auf Taten („Wendy heilt drei Verbündete, die Gruppe lobt sie“).

### Ereignisse in einer Mission (`triggers` in `data/missions/<id>.json`)
Ein Ereignis = `when` (Auslöser) + optional `if` (Bedingung) + `do` (Schritte). Jedes feuert höchstens einmal. Geprüft wird nach jeder Aktion und zu Beginn jeder Phase.

| `when` | Bedeutung | wer ist `$hero` |
|---|---|---|
| `{"turn": 3}` | Beginn von Runde 3 | – |
| `{"enter": [x, y]}` | eine Figur betritt das Feld | die Figur |
| `{"object": {"id", "state"}}` | Weltobjekt hat Zustand (Tor offen …) | – |
| `{"heal": {"by": "wendy", "targets": 3}}` | Heilung erreicht mindestens N Verbündete | die Heilerin |
| `{"ability": {"id": "fasswurf", "by": "braumeisterin"}}` | Fähigkeit wird benutzt (`id`, `by` optional) | die Nutzerin |
| `{"kill": {"id": "bienenmaedchen", "count": 3}}` | Gegner besiegt (bestimmter Typ und/oder Anzahl insgesamt) | der Sieger |
| `{"first_kill": true}` | erster besiegter Gegner | der Sieger |
| `{"fall": {"id": "wendy"}}` | Held fällt (`{}` = irgendein Held) | der Gefallene |
| `{"hp_below": {"id": "ritter", "ratio": 0.5}}` | Leben unter Anteil | die Figur |
| `{"near": {"a": "samurai", "b": "soldat_beritten", "dist": 3}}` | zwei Figuren nahe beieinander (`b` auch `"any_enemy"`) | `a` |
| `{"enemies_left": 2}` | höchstens N Gegner übrig | irgendein Held |

Bedingungen `if`: `{"present": ["ritter", "wendy"]}` (alle leben noch), `{"absent": ["wendy"]}`, `{"object": {...}}`.
Schritte `do`: `{"dialogue": [...]}` (Zeilen mit `"left"/"right"/"speaker"/"text"`, `"left_expr"/"right_expr"`, `$hero` als Platzhalter, `text_by` je Figur), `{"popup": "Text"}`, `{"spawn": [{"id", "pos", "carry"}]}`, `{"world": {"id", "effect"}}`.

Beispiele sind in Mission 1 bis 3 eingetragen (Heilung loben, Stachelia trifft Mira, Takeda und der Reiter, Robo und die Büttel, Brunhildes Fasswurf-Spruch). Test: `tests/test_events.gd`.

## Wiederkehrende Gegner (Flucht statt Tod)

Benannte Gegner (`"flees": true` in `units.json`: Wart, Oskar, Maja) sterben nicht. Fallen sie auf 0 Leben, lassen sie ihre Beute fallen, ein Fluchtdialog mit wütendem Portrait läuft (`"flee": {id: [Zeilen]}` in der Mission, sonst ein Standardsatz), dann rennen sie zum nächsten Kartenrand. Für das Ziel „alle besiegen“ zählen sie als erledigt.

- Die Party merkt sich Entkommene (`Party.nemesis`, im Speicherstand). Der Kampf liest sie als `nemeses`.
- In späteren Missionen prüft die Bedingung `"if": {"fled": ["wart"]}` darauf. Beispiel Mission 3: Runde 3 kehrt Wart mit Dialog und frischer Rakete zurück (`spawn`). Ohne Vorgeschichte, etwa über den Levelwähler, erscheint er nicht.
- Fliehen sie erneut, bleiben sie vermerkt. Noch offen: Oskar und Maja kehren erst in einer späteren Mission zurück, Xiùlán ist aufgehoben.

## Mission 4: Das Teehaus am Pass (Geisel)

- **Ziel (Pflicht):** Geisel befreien (`goal: free`). Ein Held auf einem Nachbarfeld wählt „Befreien“, die Mutter (Lieselotte, Platzhalter) rennt davon. Geisel und Teehaus sind Weltobjekte (`hostage`, `teahouse`) und sperren ihr Feld.
- **Lärm-Uhr:** Das Baby schreit, in Runde 2, 4 und 6 kommt Verstärkung vom Kartenrand (`turn`-Auslöser mit `spawn`). Keine harte Frist.
- **Xiùlán:** Wache an der Tür, wirft ihr Gebiss (Fernangriff, Abklingzeit 3). Fällt sie unter 50 % Leben, solange die Geisel gefesselt ist, bricht sie ab (`retreat`-Schritt, Bonusziel „überzeugt“) und merkt sich als Entkommene. Wird sie besiegt, flieht sie wie die anderen Benannten.
- **Bonus:** Alle Wachen besiegt (60 Gold), Xiùlán überzeugt (Äther).
- Gruppe: Mira, Meister Lin, Albrecht, Wendy, Kage-Schwestern, Elisabeth.
- Simulator: Mission 4 ist dort noch nicht abgebildet (Geisel, Verstärkung).

## Mission 5: Stachelias Rückkehr (Waisenhaus, Bienen)

- **Ziel:** alle Gegner besiegen (Stachelia, Bienenkrieger). Bonus: Kein Kind wird gestochen (70 Gold), Stachelia zum Rückzug überzeugt (2 Heilhonig).
- **Bienenstöcke** (3, Weltobjekt `hive`, 22 Leben, angreifbar): alle 2 Gegnerphasen schlüpft ein Bienenkrieger (höchstens 6). Der Schwarm zieht zum Waisenhaus, wenn kein Held in Reichweite ist. Eine Biene neben dem Haus sticht die Kinder (`kids_stung`).
- **Glocke** (Weltobjekt `bell`): ein Held daneben wählt „Glocke läuten“. Die Kinder weisen in Runde 2 und 4 darauf hin, weil sie zu klein sind. Zwei Runden später kommt der Hundsfreund als Held ins Gefecht (Schritt `later` mit `fire`, Ereignis `id: hund` mit `when: {manual: true}`). Er schließt sich am Ende der Gruppe an.
- **Honigtöpfe** (Truhen mit `look: honey`): Heilhonig (heilt 10, entfernt Gift).
- **Stachelia:** 50 Leben und Angriff 7 (Kartenfeld `atk_mult` 1,1; früher 40 Leben, Angriff 6), Wendung bei unter 50 % (die Kinder bitten sie), dann Rückzug. Später als Spezialfähigkeit: Bienen rufen und Heilhonig fallen lassen.
- **Neue Technik:** `later`-Schritt (zeitversetztes Ereignis), `spawn` mit `team: p`, `hp`-Überschreibung für Gegner, Wachen-Marke `schwarm`.
- Simulator: abgebildet (Stöcke, Glocke, Hundsfreund, Stiche, Rückzug), Messung in `docs/balance.md` Abschnitt 9. Startaufstellung: Stachelia (50 Leben) und 5 Bienenkrieger.

## Mission 6: Möwenbucht (Hafenstadt, Ziel: Schiff)

- **Ziel:** **ein Held** erreicht das goldene Feld am Ende des Stegs (`reach`). Ein „Alle Helden“-Ziel ging nicht, weil das Feld besetzt ist, sobald ein Held darauf steht. Verloren: alle Helden gefallen.
- **Härte:** Das Zielfeld und der Steg sind von Büttel und Bogenschützen besetzt, eine **Kisten-Sperre** (Fässer, hp 14) riegelt die Gasse bei x = 6 ab und lässt nur bei y = 5 eine Lücke. Die Breitseite räumt Kisten weg.
- **Breitseite:** Elisabeth bekommt in dieser Mission (`grants` in `missions/ch6.json`) die Fähigkeit `breitseite`: ein Gegner (oder eine Kiste) in 3 bis 9 Feldern Entfernung, ×1,4 Schaden plus Nachbarn 50 %, Abklingzeit 3. Der Schuss startet am Schiff (Objekt `ship`).
- **Gegenspieler:** **Wart** erscheint in Runde 3 **immer** auf dem Steg (auch im Levelwähler ohne Vorgeschichte). Die Trainingsattrappe war als Gegenspieler vorgesehen und wurde wieder entfernt (Einheit `dummy` und Fähigkeit `wirbel` bleiben in den Daten, sind aber unbenutzt).
- **Verstärkung** kommt per Beiboot vom Hafen (Runde 5, rechts unten), nicht mehr vom Stadttor.
- **Gruppe:** Hundsfreund, Mira, Elisabeth, Albrecht, Robo (Heiler), Takeda.
- **Neue Bausteine:** Terrain `P` (Holzsteg, laufbar), Objekte `ship` (Sprite) und `crate` (Kisten und Fässer, zerstörbar), Missionsfeld `grants`, goldene Zielmarkierung.
- **Simulator:** abgebildet (Ziel, Grants, Breitseite, Runden-Spawns der Mission mit Vorgeschichte `nemesis`). Messung in `docs/balance.md`, Abschnitt 10.

## Mission 7: Sandhafen (Wüste, Zwillinge)

- **Ort:** Der Hafen, an dem das Schiff aus Mission 6 ankommt. **Neues Biom Wüste** (Kartenfeld `biome: "wueste"`): Sandboden im Shader, Dünen (`D`, Bewegung 2), Kakteen auf `F`-Feldern, Oase mit Palmen (`decor`), Zelte (`tent`) als Hindernisse, Lehmhäuser.
- **Ziel:** alle Gegner besiegen. Die **Zwillinge Oskar (34 Leben) und Maja (30 Leben, die Grundwerte aus `units.json`) fliehen diesmal nicht** (Missionsfeld `no_flee: ["oskar", "maja"]`), sie müssen fallen. Beim Fall des einen reagiert der andere.
- **Gruppe:** Elisabeth, Hundsfreund, Mira, Albrecht (tauschbar) und die neuen Heiler **Lumi Sternenglanz** und **Dr. Humbug**, die in der Einleitung zur Gruppe stoßen.
- **Keine Verstärkung** mehr (früher zwei Büttel in Runde 4) und keine erhöhten Leben der Zwillinge (früher 36 und 32): Die Simulation zeigte die Mission als deutlich schwerer als Mission 8 (bei ×1,25 gewonnen: 76 % gegen 99 %); mit der Änderung 95 % (`docs/balance.md`, Abschnitt 12).
- **Simulator:** abgebildet (E11, `docs/balance.md` Abschnitt 12).

## Änderung Mission 3 (Dr. Humbug) und Mission 7
- **Mission 3:** Dr. Humbug stößt zur Gruppe (Einleitung und Abschluss), er ersetzt Käpt'n Elisabeth. Eines der vier Häuser ist **seine Praxis** (`praxis`, eigener Sprite `fx_haus_praxis`), Bonusziel „Dr. Humbugs Praxis bleibt heil“ (Heilhonig und 40 Gold). Dazu **Nachschub in Runde 4**: ein Bogenschütze und ein Büttel am rechten Rand.
- **Wählbar ab Mission 3** (`intro` und `from` in `units.json`). **Mission 7:** Er ist schon im Team, nur Lumi wird dort eingeführt.

## Mission 8: Die bewachte Oase (Wüsteninsel, Robinas Panzer)
- **Lage:** Im Inneren der Wüsteninsel, sehr heiß und trocken. Die Helden wollen zur Oase, doch sie wird von Xiùlán und Soldaten des Regenten bewacht (Büttel, Bogenschützen, Priester, ein Reiter). Xiùlán kann wieder fliehen (Nemesis, Rückzugsdialog).
- **Runde 5:** Robinas Dampfpanzer rollt vom Ostrand heran (`spawn` in `missions/ch8.json`). Robina ist Robos ältere Schwester: Dialog zwischen Robo und ihr. Sie kämpft für den Regenten, hat dieselbe Fähigkeit wie Elisabeths Schiff (**Breitseite**, Reichweite 3–9, Abklingzeit 3, `ai_bonus` für die Gegner-KI), aber auf der Gegenseite. Elisabeth kommentiert die erste Salve.
- **Ziel `capture`:** Der Panzer ist **unantastbar** (Marke `unantastbar`: kein Ziel von Angriffen, Fähigkeiten, Flächen und Streuschaden). Wer **drei Runden in Folge** (am Ende der Spielerphase) mit mindestens einem Helden neben ihm steht, übernimmt ihn: Er wechselt auf die Spielerseite, die Mission ist gewonnen. Unterbrochene Zählung beginnt von vorn. Zieltext mit Fortschritt (x/3), Popups je Runde, Übernahme-Effekt (`Battle._capture_phase`, `_capture_unit`).
- **Gruppe:** Robo, Mira, Albrecht und Elisabeth sprechen und sind gesperrt; die übrigen zwei Plätze (Standard: Wendy, Dr. Humbug) sind frei wählbar.
- **Belohnung:** 180 Gold, Bonusziele „Kein Held fällt“ (80 Gold) und „In 11 Runden gewonnen“ (Heilhonig).
- **Grafik:** Robina als Porträt (neutral, lachend, wütend) und großer Panzer-Sprite (`size` 2,1 in `units.json`), Gemini.
- **Balancing:** Der Simulator kennt den Panzer (E12, `docs/balance.md` Abschnitt 13): unantastbar, Breitseite, Übernahme nach drei Runden; mit zwei Helden am Panzer gewinnt die Gruppe bei ×1,25 zu 99 %, bei ×1,5 zu 75 %.
- **Test:** `tests/test_capture.gd`.

## Mission 9: Die Festung im Gebirge (Wüsteninsel, Wart und die Frischlinge)
- **Lage:** Das Land wird gebirgig (Berge `M`, Bewegung 3, Deckung). Auf dem Pass steht eine bedrohliche, dunkle Festung (`decor`, Sprite `fx_festung`). Wart bewacht sie und hat diesmal **Wartens Frischlinge** dabei: drei kleine, fiese Wildschweine mit Stachelkeulen und Äxten, die als **eine Figur** (`frischlinge`, Leben 38, Größe 2,1) kämpfen. Dazu Büttel, Bogenschützen, Priester und ein Reiter.
- **Ziel `defeat`:** Wart besiegen (Missionsfeld `no_flee: ["wart"]`, er flieht nicht mehr). Die Frischlinge fliehen wie üblich, wenn sie fallen (Rückzugsdialog).
- **Abschlussszene (Ziel-Feld `then`, neu):** Zuerst Warts **theatralische Todesszene** im Dialogformat (Porträt `wart_sterbend`, Ausdruck `sterbend`: verdrehte Augen, Sternchen, Heiligenschein). Dann schwören die Frischlinge **wütend Rache** (nur wenn sie noch da sind) und laufen weg (`retreat`, nur wenn noch da), der Regent tritt aus der Festung (`spawn`) und gesteht in der **weinerlichen Grafik** (`fuerst_weinerlich`, Ausdruck `weinerlich`), dass er nur ein **Strohmann** für eine größere, noch unbekannte Bedrohung ist; danach zieht er sich zurück. Die Szenen sind gewöhnliche Gespräche mit `when: {"victory": true}` (im Texteditor als „Abschlussszene“ sichtbar und bearbeitbar); sie laufen in Reihenfolge in `Battle._check_end` vor dem Sieg-Signal.
- **Sackgasse und Licht:** Kartenfeld `walls: ["n","e","w"]` lässt das Gelände hinter der Karte zu einer Felswand ansteigen (`TerrainView.wall_sides`), damit die Karte nicht offen wirkt: Hier endet das Kapitel auf der Insel. Kartenfeld `mood: "duester"` dunkelt die Mexiko-Stimmung ab (tiefere rote Sonne, rauchiger Himmel, Dunst, stärkere Vignette; `Battle._apply_desert_light`).
- **Gruppe:** Robina (Panzer) ist ab hier wählbar (`from: 9`); sonst Standard wie Mission 8.
- **Belohnung:** 200 Gold, Bonusziele „Kein Held fällt“ (90 Gold) und „In 10 Runden gewonnen“ (Heilhonig).
- **Hinweis:** Die Datei heißt `ch9`, weil Kapitel 8 die Oase ist; im Gespräch „Mission 8“.
- **Simulator:** noch nicht abgebildet (Ziel `defeat` und Frischlinge-Werte ungeprüft, Balancing offen).
- **Test:** `tests/test_festung.gd`.

## Kapitel 2: Zwischenspiel „Die Suche nach der wahren Gefahr“ (`ch10`, ohne Kampf)
- **Zählung:** Die Titelkarte „Kapitel 2“ beginnt den zweiten Abschnitt; die Missionen 1–9 gelten rückwirkend als Kapitel 1, intern zählen die Dateien weiter (`ch10`, `ch11` …).
- **Ablauf:** Nach Mission 9 folgt ohne Lager das Reisebild: Die „Rostige Möwe“ segelt in der Engine über das Meer (**3D-Szene** `scene: "sea"`: Wellen-Shader `sea.gdshader` (bewegte Wellen mit Schaumkämmen, aus dem Karten-Wasser abgeleitet), Schiffs-Sprite, das die Wellenhöhe mitgeht, mit Wasserlinie und Kielwasser, tiefe Abendsonne, Kamera gleitet in einem Bogen mit, 8 s; ein Ken-Burns-Standbild `assets/ui/reise_schiff.jpg` blieb als Alternative ohne `scene`, ruckelte aber), Schwarzblende, Titelkarte „Kapitel 2 / Die Suche nach der wahren Gefahr“. Klick oder Taste überspringt. Danach das **Hafen-Gespräch** (`story_ch10.json`, Einleitung) vor der Möwenbucht-Karte (`map_ch10.json`, Kopie von Mission 6 ohne Elisabeths Breitseite-Grant).
- **Bausteine:** `Interlude` (`scripts/interlude.gd`), Missionsfeld `stub: true` (Kapitel ohne Kampf, wird in `Main._interlude_chapter` abgespielt) und `interlude: {image, kicker, title, duration, zoom, pan}`. Das Reisebild lässt sich für spätere Überfahrten mit anderem Bild wiederverwenden. Screenshot: `SHOT=interlude SHOT_DELAY=4.5`.
- **Offen:** die Kampfmission in Möwenbucht (Ort: `map_ch10.json`, Mission `ch10` wird dann zur echten Mission).
- **Test:** `tests/test_interlude.gd`.
- **Überfahrt zwischen Mission 6 und 7:** Der Abschluss von Mission 6 (Gespräch Hundsfreund, dem schlecht ist, und Elisabeth, danach Robo und Mira; im Texteditor unter „Abschluss“ von Kapitel 6) läuft **vor der fahrenden Möwe** auf dem Meer (Missionsfeld `outro_at_sea: {scene: "sea", dir: "right", speed: 1.8}`, `Main._dialogue_at_sea`; die Szene läuft bis zum Gesprächsende, dann Schwarzblende). Das Schiff fährt nach rechts (gespiegelt). Für eine Überfahrt ohne Gespräch gibt es weiter `interlude_before`. Screenshot: `SHOT=interlude SHOT_CH=ch6 SHOT_LINE=2`.

## Kapitel 2 weiter: Hafen bei Nacht und Mission 11 „Stachelias Stand“
- **Hafen bei Nacht und Regen (`ch10`, Einleitung nach der Überfahrt):** Kartenfeld `mood: "nacht_regen"` (`Battle._apply_night_rain`): Mondlicht, tiefblauer Himmel, Dunst, kühler Farbfilter, dichter Regen (`_build_rain`, CPUParticles3D), warme Fensterlichter an den Dorf-Feldern (`_window_glow`). Die Barrikaden (Kisten) sind entfernt. **Lotte** (die älteste Waisenkind, neue Figur `lotte`, Porträts neutral/lachend/wütend) hat auf die Gruppe gewartet und erzählt dem Hundsfreund, dass die anderen Kinder entführt wurden (Schiff mit schwarzen Segeln). Danach Schnitt.
- **Mission 11 `ch11` „Stachelias Stand“:** Stachelia steht allein im Bienenwald, mit zwei Drohnen und **vier dauerhaften Bienenkörben** (Objekt `hive_p` mit `perm: true`, alle zwei Runden eine neue Drohne, höchstens `drone_cap` 4). Der Spieler führt Stachelia (42 Leben, Kartenfeld `hp` bei den Spielern) und die Drohnen; der Trupp ist fest (`fixed_squad`, keine Gruppenwahl). Runde 2: Oskar und Maja tauchen mit Soldaten auf (wollen den magischen Honig für das geheimnisvolle Böse), Runde 4: Verstärkung. Ziel `survive` 8 Runden.
- **Erzählte Niederlage (`story_loss: "bienenmaedchen"`):** Fällt Stachelia, flieht sie stattdessen (`Battle._down`, `story_lost`), die Mission gilt als geschafft. Nach dem Durchhalten oder ihrer Flucht laufen die Abschlussszenen (`when: {"victory": true}`): das Feuer der Zwillinge brennt die Körbe nieder (neuer Schritt `{"burn": "hive_p"}`), Stachelia flieht und schwört Rache (`retreat`). Bonusziel `durchgehalten` („8 Runden ausgehalten“, 2 Heilhonig) nur, wenn sie die Runden geschafft hat.
- **Übergang:** Nach dem Hafen-Gespräch Schwarzblende, Textkarte „Währenddessen, an einem anderen Ort ...“ (Missionsfeld `card_after`, `Main._scene_card`), währenddessen wechselt die Karte, dann Aufblende auf die Bienen.
- **Schwarzblende zwischen allen Missionen:** Am Ende eines Kapitels (nach dem Lager) blendet das Bild in 0,4 s nach Schwarz, der nächste Schauplatz wird dahinter aufgebaut und in 0,5 s aufgeblendet (`Main._cover_in`, `_cover_out`), ohne Text. Auch die Schiffsfahrten (Reisebild von Kapitel 2, Überfahrt nach Mission 6) werden weich ein- und ausgeblendet; am Ende bleibt das Bild schwarz, bis der nächste Schritt (Lager, Hafen-Gespräch) aufblendet.
- **Offen:** Balancing (der Simulator kennt Mission 11 nicht), Rückkehr der Kinder, Stachelias weiterer Weg.
- **Tests:** `tests/test_stachelia.gd`, `tests/test_interlude.gd`.

## Mission 12: Die hochgezogene Brücke (`ch12`, Fluss mit Zugbrücke)
- **Lage:** Ein Fluss teilt die Karte, die **Frischlinge** (Rache für Wart) haben die Zugbrücke an ihrem Ufer **hochgezogen** (keine Sprengung mehr, Entscheidung des Nutzers). Auf der anderen Seite steht **eine** Frischlinge-Figur als Boss-Ersatz für Wart (55 Leben, ×1,15 Angriff), dazu zwei Bogenschützen, zwei Büttel und ein Priester. Die Helden starten ganz links; der Hebel steht **ein Feld vom Ufer entfernt**. Der Wachturm der Schweine (Sprite `fx_wachturm`, Gemini, fertig und im Projekt) passte nicht zur Mission und ist für später aufgehoben. Der Hund erreicht ihn von dort nicht mehr (Knochenwurf Reichweite 2); die Frischlinge-Szene liegt in der Einleitung, damit sie vor dem ersten Zug kommt.
- **Mechanik (neu): Zugbrücke.** Weltobjekt `bridge` (Zustand `up` sperrt das Wasserfeld, `open` macht es begehbar: `Grid.bridges`, `World.open_bridges`, `Battle._make_bridge`, reine Mesh-Optik, klappt animiert herunter). Ein **Hebel** (`switch`, `link: ["bruecke"]`) auf der Feindseite lässt sie herab. Den Hebel legt man um, wenn man **daneben steht oder ihn mit einer Fernkampf-Fähigkeit trifft** (Marke `ranged_hit`: Elisabeths Kanone, Knochenwurf des Hundes, Takedas Kyujutsu, Robinas Breitseite, Lumis Sternschnuppe). Alternativ kommen Flieger und der Wurf hinüber. Gegner nutzen die Brücke nach dem Herablassen ebenso.
- **Ziel:** alle Gegner besiegen. Belohnung 220 Gold, Bonus „Kein Held fällt“ und „In 12 Runden“ (Heilhonig).
- **Test:** `tests/test_fluss.gd`. Die hochgezogene Brücke steht senkrecht am Ostufer (Drehpunkt dort).

## Mission 13: Das Labor im Wald (`ch13`, Professor Kugelblitz)
- **Neuer Gegenspieler Professor Kugelblitz** (`kugelblitz`: Porträts neutral/lachend/wütend, Chibi, 55 Leben, roter Laser, flieht): verrückter Erfinder mit Tesla-Stab. Er hat die Kinder (Lotte, Pip, Mia) in seiner Gewalt und will ihnen mit der **Energiemaschine** und dem magischen Honig als Katalysator die Energie für den Meister entziehen.
- **Maschine (neu, Objekt `maschine`, Sprite `fx_maschine`, 30 Leben):** leuchtet cyan (Punktlicht), **schockt jede Gegnerphase alle Helden direkt daneben** (Kartenfeld `zap`, in Mission 13 auf 3 gesenkt, Standard 5, `Battle._machine_phase`). Lässt sich zerstören (Bonusziel „Die Maschine ist zerstört“, Heilhonig ×2).
- **Ziel `free_all`:** alle drei Kinder befreien (Geisel-Mechanik aus Mission 4: zwei Runden neben dem Kind, keine Wache daneben, Figuren `kind_lotte`, `kind_pip`, `kind_mia`). Danach Abschlussszenen (`when victory`): Wiedersehen mit den Kindern, der Professor flieht mit der Drohung des Meisters.
- **Aufstellung:** Die Helden starten ganz im Südwesten (freie Wiesenecke unten links, vier bis acht Felder vom Feind), die Gegner stehen in der Mitte und im Osten um die Maschine.
- **Stimmung:** Kartenfeld `mood: "gewitter"`: Nachtwald wie „nacht_regen“ mit **Regen und Gewitter** (`Battle._storm_loop`): alle 4,5 bis 10 Sekunden zuckt ein gezackter Blitz mit Aufhellen des Bilds und hellem Mondlicht, kurz darauf grollt der **Donner** (`thunder`, drei Varianten aus `tools/make_sfx.py`). Das Feld `mood: "nacht"` gibt es weiter (Nacht ohne Regen).
- **Offen:** Balancing beider Missionen im Simulator (kennt weder Zugbrücke noch Maschine), Dialoge zum Verfeinern im Texteditor, Kapitelwahl „Hebel, Brücke“ nur im Test sichtbar.
- **Test:** `tests/test_labor.gd`.

### Mission 13, Überraschung: Cyborg-Wart
- **Der Behälter:** Ein grünlicher Glaszylinder in Humanoidengröße steht neben dem Professor (Objekt `zylinder`, Sprites `fx_glaszylinder` heil und `fx_glaszylinder_kaputt` geborsten, grünes Glühen). Er ist eindeutig als technisches Gerät zu erkennen (Stahlsockel, Kontrollleuchten, Kabel, Schatten einer Gestalt in der Flüssigkeit).
- **Auslöser:** Die **Frischlinge** (in Mission 13 wieder dabei, 55 Leben) fallen unter **50 % Leben**: Kugelblitz öffnet „Behälter Sieben“, der Zylinder birst (`{"world": … "break"}`, Funken, Lichtblitz, Beben), und **Cyborg-Wart** erscheint (`spawn`) mit eigenem Dialog. Die Bösen haben Wart als Cyborg wiederbelebt, wütend und stärker.
- **Cyborg-Wart (`cyborg_wart`):** Porträts neutral/lachend/wütend (Stahlzahn, rotes Kamera-Auge, Chromarm, Raketenwerfer), Karten-Figur. 72 Leben, Angriff 13, Verteidigung 6, **Raketenwerfer** wie zuvor und neu **Computer-Analyse** (`computer_analyse`, Reichweite 1–4, Abklingzeit 3, kostet keine Aktion): Das Ziel ist 3 Runden **analysiert** und **nimmt 20 % mehr Schaden** (`Status` `analysiert`, `Combat.damage`). Die Gegner-KI setzt sie vor dem Angriff ein (`ai_debuff`, `Battle._enemy_debuff`), Effekt `Fx._scan` (cyanfarbener Abtaststrahl).
- **Offen:** Balancing (der Simulator kennt Mission 13 nicht; Cyborg-Wart macht sie deutlich schwerer), Stufenwerte nach Spielgefühl anpassen.

- **Entschärft (2026-11-03, nach Spieltest „sehr hart“):** Gegnerfaktor von 1,7 auf 1,3, Maschinenschock von 5 auf 3. Weitere Optionen im Backlog: Cyborg-Wart schwächer oder später, Stachelia-Verstärkung in Runde 4.

## Mission 13, Nachtrag: Cyborg-Wart bricht am Ende immer aus
Fällt die Gesundheit der Frischlinge nie unter 50 %, platzt der Glasbehälter trotzdem in der **Abschlussszene** (Auslöser `victory` mit Bedingung „Behälter heil“): Der Hund und die Kinder hören das Knacken, Cyborg-Wart tritt heraus (er steht danach auf der Karte) und droht mit „Wir sehen uns wieder“. So sieht der Spieler auch ohne Eingreifen, dass Wart zurück ist.

## Mission 14: Das brennende Waisenhaus (`ch14`)
- **Lage:** Es ist wieder Tag, Karte mit dem Waisenhaus (großes Haus-Sprite `fx_waisenhaus`, in den Daten ein brennbares `house` mit `look` und `burn: 2`). **Fünf Helden** starten (Mira, Hundsfreund, Brunhilde, Albrecht, Wendy). Gegner: Oskar und Maja mit drei Bütteln, zwei Bogenschützen und einem Priester.
- **Feuer:** In Runde 2 zünden die Zwillinge das Waisenhaus an (neuer Effekt `ignite` für Weltobjekte). Es brennt **zwei Gegnerphasen lang** (Objektfeld `burn`, Standard sonst 3). Die Helden haben **zwei Runden zum Löschen**: neben das Feuer stellen und löschen, oder mit **Brunhildes Fasswurf** wie in Mission 3. Brennt es ab, ist die Mission **verloren** (Kartenfeld `lose_if_ruin`).
- **Stachelia:** In **Runde 4** greift sie ein (`spawn` mit `team: "p"`), will Rache für ihre Bienenkörbe und kämpft als **sechste Heldenfigur** unter deiner Steuerung, bleibt aber abweisend und garstig. Sie ist erst ab **Mission 15** wählbar (`from: 15`), im Abschluss schließt sie sich dem Team an („nur aus Berechnung“).
- **Bonus:** „Kein Held fällt“ (100 Gold), „Das Waisenhaus brennt nicht ab“ (2 Heilhonig). Gegnerfaktor 1,4 (nicht gemessen, der Simulator kennt Mission 14 nicht).
- **Test:** `tests/test_waisenhaus.gd`.

- **Nachgestellt (2026-11-03, Spieltest mit üblicher Ausstattung):** Mit Talenten und Ausrüstung der Zielkurve war Mission 13 bei ×1,3 zu leicht: Gegnerfaktor wieder **×1,7** (der Maschinenschock bleibt bei 3), Mission 14 von ×1,4 auf **×1,6**.

## Mission 14, Abschluss: Beratung und Lieselotte (2026-11-03)
Das Waisenhaus ist endgültig gerettet, die Gruppe berät. **Stachelia** gibt zähneknirschend zu, dass sie den Meister auch nicht kennt, aber **ihn vernichten muss**, wenn sie in Ruhe mit ihren Bienen leben will. Dann taucht **Lieselotte** (die Mutter mit dem Baby) auf: Sie sollte entführt werden, weil sie das Geheimnis kennt, hatte aber Angst zu sprechen. **Der Meister versteckt sich in den Bergen im hohen Norden.** Die Gruppe bricht auf, Lieselotte warnt vor dem Sumpf. (Text im Texteditor unter dem Abschluss von Kapitel 14.)

## Mission 15: Der Sumpf vor den Bergen (`ch15`, neues Biom Sumpf)
- **Neues Biom Sumpf** (Kartenfeld `biome: "sumpf"`, `mood: "sumpf"`): Gelände **`S` Sumpf** (Bewegung 2), mooriges Olivgrün im Bodenshader, trübes Grünbraun im Wasser, gelbgrüner Dunst mit fahlem Licht (`Battle._apply_swamp`). Streuobjekte als Sprites: **toter Baum** (`fx_totbaum`), **Schilf** (`fx_schilf`) und **leuchtende Sumpfpilze** (`fx_sumpfpilz`, als `decor`), alle von Gemini. Sumpffelder sind als **weicher, ausgefranster Schlamm** im Bodenshader dargestellt (`swamp_mask`: eine Maske je Kachel, weich gefiltert und durch Rauschen verformt, ohne harte Kachelkanten wie beim Wasser-Ufer; dazu Algen- und Mooreinschlüsse), damit man sie vom festen Boden unterscheidet. Die früheren eckigen Overlay-Quadrate (`_build_swamp_overlay`) sind weg.
- **Sumpfgas:** Wer zu **Beginn seiner Phase** im Sumpf steht, nimmt **2 Schaden** (`sumpf_dmg`, nach Spieltest von 3 gesenkt). **Flieger** (Stachelia, Bienen) sind verschont, Gras ist sicher. Das gilt für alle Seiten.
- **Gegner:** Cyborg-Wart (flieht jetzt) und die Frischlinge (55 Leben) stellen sich in den Weg, dazu Büttel, Bogenschützen und ein Priester. Gegnerfaktor ×1,7 (nicht gemessen).
- **Gruppe:** Mira, Hundsfreund, Albrecht, Wendy, Robo und **Stachelia** (ab hier wählbar, Heldin).
- **Test:** `tests/test_sumpf.gd`.

- **Weniger Sumpf (2026-11-03, Spieltest „viel zu viel Sumpfgas“):** Statt eines Sumpffelds über fast die ganze Karte jetzt **17 von 120 Feldern** (einzelne Moorstreifen und -tümpel, viel festes Gelände dazwischen), Sumpfgas 2 statt 3 Schaden.

## Korrektur Mission 15 und Mission 16: Streit um den Sold (`ch16`, Sumpf)
- **Mission 15:** Die Berge im Norden sind **weg** (zu früh): keine Bergfelder, keine Felswand mehr (`walls` entfernt). Der Abschluss sagt jetzt, dass der Sumpf weitergeht und dahinten streitende Stimmen zu hören sind.
- **Mission 16** (noch im Sumpf, Karte mit 17 Sumpffeldern, Sumpfgas 2): Die Gruppe trifft **Professor Kugelblitz**, der sich gerade mit der Söldnerin **Xiùlán** über die Bezahlung streitet. Als die Helden erscheinen, beginnt der Kampf. **Xiùlán fragt in Runde 2, 4 und 6 immer wieder nach dem Geld** (Dialoge mit Auslöser `turn`).
- **Zwei Truhen auf der Karte** (je 80 Gold): Beim **ersten** Öffnen warnt Xiùlán („Wehe, ihr fasst die andere auch an!“), beim **zweiten** glaubt sie, ihr Lohn sei verloren, kündigt und **verschwindet** (`retreat`), Kugelblitz ruft ihr hinterher. Neuer Auslöser **`chests_open`** (so viele Truhen sind geöffnet; auch im Texteditor wählbar: „Truhen geöffnet“). Xiùlán flieht sonst nicht (`no_flee`), sie muss besiegt werden oder abziehen.
- **Gegner:** Kugelblitz (55 Leben), Xiùlán (50), zwei Büttel, zwei Bogenschützen, ein Reiter, ein Priester. Gegnerfaktor ×1,8 (nicht gemessen).
- **Bonus:** „Kein Held fällt“ (110 Gold), „Alle Gegner besiegt“ (2 Heilhonig).
- **Test:** `tests/test_sumpf.gd`.

- **Berge nur in Mission 16 (2026-11-03):** Die angedeutete Felswand im Norden (Bergfelder in den obersten Reihen, `walls: ["n"]`) gehört zur **zweiten** Sumpfmission (`ch16`), damit die Reise zu den Bergen nachvollziehbar wird; Mission 15 bleibt ohne Berge.

- **Nebelschwaden im Sumpf (2026-11-03):** Auf allen Sumpf-Karten ziehen große, weiche, langsam wandernde Dunstwolken dicht über dem Boden, dazu leuchtende Sporen (`Battle._build_swamp_fog`, CPUParticles3D mit weicher Scheibe). Die Dichte folgt der Grafikoption „Partikel und Regen“.

- **Weicher Schlammübergang (2026-11-03):** Die Sumpffelder waren als eckige Quadrate hart abgegrenzt und wirkten wie ein Grafikfehler. Jetzt fließt der Schlamm organisch in den Boden über (`ground.gdshader`, `swamp_mask`, `TerrainView`). Die Kachelgrenzen bleiben als Spielraster erkennbar.
