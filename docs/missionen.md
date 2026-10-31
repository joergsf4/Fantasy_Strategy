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
| 1 | Eichenfurt brennt | Rettung | Feuer löschen (Bier, Fasswurf), Dorfbewohner retten, erster Kampf. Lehrt die Interaktion. |
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
- **Stachelia:** 40 Leben, Wendung bei unter 50 % (die Kinder bitten sie), dann Rückzug. Später als Spezialfähigkeit: Bienen rufen und Heilhonig fallen lassen.
- **Neue Technik:** `later`-Schritt (zeitversetztes Ereignis), `spawn` mit `team: p`, `hp`-Überschreibung für Gegner, Wachen-Marke `schwarm`.
- Simulator: abgebildet (Stöcke, Glocke, Hundsfreund, Stiche, Rückzug), Messung in `docs/balance.md` Abschnitt 9. Startaufstellung: Stachelia (40 Leben) und 5 Bienenkrieger.

## Mission 6: Möwenbucht (Hafenstadt, Ziel: Schiff)

- **Ziel:** **ein Held** erreicht das goldene Feld am Ende des Stegs (`reach`). Ein „Alle Helden“-Ziel ging nicht, weil das Feld besetzt ist, sobald ein Held darauf steht. Verloren: alle Helden gefallen.
- **Härte:** Das Zielfeld und der Steg sind von Büttel und Bogenschützen besetzt, eine **Kisten-Sperre** (Fässer, hp 14) riegelt die Gasse bei x = 6 ab und lässt nur bei y = 5 eine Lücke. Die Breitseite räumt Kisten weg.
- **Breitseite:** Elisabeth bekommt in dieser Mission (`grants` in `missions/ch6.json`) die Fähigkeit `breitseite`: ein Gegner (oder eine Kiste) in 3 bis 9 Feldern Entfernung, ×1,4 Schaden plus Nachbarn 50 %, Abklingzeit 3. Der Schuss startet am Schiff (Objekt `ship`).
- **Gegenspieler:** die **Trainingsattrappe** (`dummy`, Boss mit Wirbel) erscheint in Runde 4 von hinten am Stadttor. **Wart** kehrt in Runde 3 auf dem Steg zurück, wenn er früher entkommen ist (`if: {fled: ["wart"]}`). Da benannte Gegner nie sterben, ist das in einem normalen Durchlauf immer der Fall.
- **Verstärkung** kommt per Beiboot vom Hafen (Runde 5, rechts unten), nicht mehr vom Stadttor.
- **Gruppe:** Hundsfreund, Mira, Elisabeth, Albrecht, Robo (Heiler), Takeda.
- **Neue Bausteine:** Terrain `P` (Holzsteg, laufbar), Objekte `ship` (Sprite) und `crate` (Kisten und Fässer, zerstörbar), Missionsfeld `grants`, goldene Zielmarkierung.
- **Simulator:** abgebildet (Ziel, Grants, Breitseite, Runden-Spawns der Mission mit Vorgeschichte `nemesis`). Messung in `docs/balance.md`, Abschnitt 10.
