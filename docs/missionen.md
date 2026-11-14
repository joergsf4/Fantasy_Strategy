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
- **Mission 21 „Die Rechnung der Xiùlán“:** Nach dem Lager von Hogsmeat führt die Vulkanreise in eine spielbare Aschelandschaft. Ein erkalteter Lavastrom durchzieht das Feld; an den Flanken stehen Felsen und verschiedenartige, farblich gedämpfte Bäume, dazu ein einzelner verbrannter Baum als Blickfang. Asche und Glut liegen in der Luft. Der Lavastrom und die Dekoration sind rein optisch und ändern keine Bewegungskosten. Eine noch ausstehende Reise bleibt beim Speichern erhalten und wird nach dem Laden einmal abgespielt; beim Cheatstart mit Einleitung zeigt die Reise die dort gewählte Gruppe, beim Direktstart entfällt sie. Auf der Kampfkarte stellen Oskar und Maja Xiùlán; nach ihrer geskripteten Gebiss-Attacke flieht Oskar, Maja und ihre Soldaten kämpfen gegen die Gruppe. Mira und die Kage-Schwestern sind gesetzt, zwei Gruppenplätze frei wählbar; Xiùlán kämpft als fünfte Einheit nur in dieser Mission mit. Die glühenden Risse sind rein optisch. Maja flieht bei ihrer Niederlage, das Ziel verlangt auch das Besiegen der Soldaten. Die Gegnerstärke ist vorläufig und noch nicht simuliert. Test: `tests/test_ch21.gd`.
- **Schritt 1 fertig:** Missionsformat (`data/missions/ch1.json`, `scripts/mission.gd`) mit Zielen (besiege alle, halte N Runden durch, erreiche ein Feld), Niederlage bei gefallenen Helden, Auslösern (Runde N, Feld betreten) für Verstärkung, Popups und **Dialoge mitten im Kampf**, Zielanzeige im HUD, Test `tests/test_mission.gd`.
- Kapitel 1 hat einen Auslöser: Runde 3 erscheint ein Büttel als Verstärkung, mit kurzem Dialog.
- **Missionsauftakt Kapitel 1:** Eine diagonale Kamerafahrt über die echte Karte zeigt Landschaft und Gegner aus einem flacheren Winkel, mit blauem Himmel und Schäfchenwolken. Die Kampfmusik beginnt zur Fahrt und läuft über den Dialog weiter. Eine Schwarzblende führt zum bisherigen Einleitungsdialog; beim Überspringen der Einleitung entfällt die Fahrt. Test: `tests/test_ch1_flyover.gd`.
- **Schritt 2 fertig:** Weltobjekte (`data/objects.json`, `scripts/world.gd`): Mauer, Tor, Schalter. Fähigkeiten bekommen Marken (`caps` in `abilities.json`) und wirken über das normale Fähigkeiten-Menü auf Objekte: Kanone sprengt Mauer und Tor, Laser schmilzt das Tor (nur auf gerader Linie), Pranke bricht das Tor, Stabsprung springt über Mauer/Tor, Knochenwurf trifft den Schalter, **Wurf wirft Verbündete** (Landefeld frei wählbar, bis 4 Felder). Flieger kommen über alles. Normale Angriffe können das Tor aufbrechen (Sicherheitsnetz, damit nie eine Gruppe festhängt). Auslöser reagieren auf Objektzustände (Tor offen/zerstört).
- **Mission 2 „Der Hohlweg“** (Mauer waagerecht quer über das Feld, Helden unten, Gegner oben, Tor in der Mitte; wer hinter dem Tor ankommt, öffnet es von innen automatisch mit einer Dialogzeile) (`data/missions/ch2.json`, `map_ch2.json`, `story_ch2.json`) ist spielbar, das Spiel läuft jetzt über zwei Kapitel mit Lager dazwischen. Tests: `test_world.gd`, `test_objects.gd`.
- Nächster Schritt: Feuer und Rettung (Mission 1 nachrüsten), danach Briefing und Heldenwahl.

- **Mission 3 „Mühlbach in Flammen“** (`data/missions/ch3.json`, `map_ch3.json`, `story_ch3.json`): Feuer als Weltobjekt (`fire`, `house`; `World.tick_fire`, 3 Phasen Brenndauer, Ausbreitung nur auf Häuser und Wald). Löschen: **Fasswurf** (Brunhilde, Umkreis 1) oder **„Feuer löschen“** (jede Figur, 1 Feld, Sicherheitsnetz). Brandschaden 4 auf Feuerfeldern, Vorschau der nächsten Zündung (orange Felder), Bonusziel „Kein Haus brennt ab“. Neben Oskar und Maja stehen drei statt fünf Soldaten: je ein Infanterist, Bogenschütze und Reiter. Test: `tests/test_fire.gd`. **Offen:** Bier als Löschmittel (Gegenstand) und Feuer im Simulator (Balancing nicht gemessen).


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

- **Ziel (Pflicht):** Geisel befreien (`goal: free`). Ein Held auf einem Nachbarfeld wählt „Befreien“, die Mutter (Bianca, Platzhalter) rennt davon. Geisel und Teehaus sind Weltobjekte (`hostage`, `teahouse`) und sperren ihr Feld.
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
- **Neuer Gegenspieler Professor Kugelblitz** (`kugelblitz`: Porträts neutral/lachend/wütend, Chibi, 38 Leben (vorher 55), roter Laser, flieht): verrückter Erfinder mit Tesla-Stab. Er hat die Kinder (Lotte, Pip, Mia) in seiner Gewalt und will ihnen mit der **Energiemaschine** und dem magischen Honig als Katalysator die Energie für den Meister entziehen.
- **Maschine (neu, Objekt `maschine`, Sprite `fx_maschine`, 30 Leben):** leuchtet cyan (Punktlicht), **schockt jede Gegnerphase alle Helden direkt daneben** (Kartenfeld `zap`, in Mission 13 auf 3 gesenkt, Standard 5, `Battle._machine_phase`). Lässt sich zerstören (Bonusziel „Die Maschine ist zerstört“, Heilhonig ×2).
- **Ziel `free_all`:** die beiden entführten Kinder Pip und Mia befreien (Geisel-Mechanik aus Mission 4, keine Wache daneben, Figuren `kind_pip`, `kind_mia`; Lotte konnte sich in Kapitel 10 verstecken und ist nicht im Labor). Mia steht rechts neben der Maschine (10, 5), nicht davor: Dort verdeckte das große Maschinenbild sie. Danach Abschlussszenen (`when victory`): Wiedersehen mit den Kindern, der Professor flieht mit der Drohung des Meisters.
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

## Mission 14, Abschluss: Beratung und Bianca (2026-11-03)
Das Waisenhaus ist endgültig gerettet, die Gruppe berät. **Stachelia** gibt zähneknirschend zu, dass sie den Meister auch nicht kennt, aber **ihn vernichten muss**, wenn sie in Ruhe mit ihren Bienen leben will. Dann taucht **Bianca** (die Mutter mit dem Baby) auf: Sie sollte entführt werden, weil sie das Geheimnis kennt, hatte aber Angst zu sprechen. **Der Meister versteckt sich in den Bergen im hohen Norden.** Die Gruppe bricht auf, Bianca warnt vor dem Sumpf. (Text im Texteditor unter dem Abschluss von Kapitel 14.)

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
- **Gegner:** Kugelblitz (38 Leben, vorher 55), Xiùlán (50), zwei Büttel, zwei Bogenschützen, ein Reiter, ein Priester. Gegnerfaktor ×1,8 (nicht gemessen).
- **Bonus:** „Kein Held fällt“ (110 Gold), „Alle Gegner besiegt“ (2 Heilhonig).
- **Test:** `tests/test_sumpf.gd`.

- **Berge nur in Mission 16 (2026-11-03):** Die angedeutete Felswand im Norden (Bergfelder in den obersten Reihen, `walls: ["n"]`) gehört zur **zweiten** Sumpfmission (`ch16`), damit die Reise zu den Bergen nachvollziehbar wird; Mission 15 bleibt ohne Berge.

- **Nebelschwaden im Sumpf (2026-11-03):** Auf allen Sumpf-Karten ziehen große, weiche, langsam wandernde Dunstwolken dicht über dem Boden, dazu leuchtende Sporen (`Battle._build_swamp_fog`, CPUParticles3D mit weicher Scheibe). Die Dichte folgt der Grafikoption „Partikel und Regen“.

- **Weicher Schlammübergang (2026-11-03):** Die Sumpffelder waren als eckige Quadrate hart abgegrenzt und wirkten wie ein Grafikfehler. Jetzt fließt der Schlamm organisch in den Boden über (`ground.gdshader`, `swamp_mask`, `TerrainView`). Die Kachelgrenzen bleiben als Spielraster erkennbar.

## Kapitel 17: Zwischenspiel „Überfall am Pass“ (`ch17`, ohne Kampf, 2026-11-05)
- **Eingeschoben** nach Mission 16. Die bisherigen Kapitel 17 und 18 heißen seitdem 18 (Wölfe der Nacht) und 19 (Der Regent im Schnee). Alte Spielstände werden beim Laden umgerechnet (`Party.ORDER`, `Party._migrate_order0`: Fortschritt ab dem alten Kapitel 17 und die gespeicherten Aufstellungen `ch17`/`ch18` rücken um eins). `Progression.missions_done_before` kennt zwei Zwischenspiele (10 und 17).
- **Szene** (`scripts/mountain_raid.gd`, Klasse `MountainRaid`, Interlude-Szene `"berge"`, Vorschau `SHOT=berge SHOT_DELAY=<Sekunde> SHOT_OUT=<png>`): Kinobalken, Kamerafahrt, alles in 3D mit den Chibi-Sprites. Die Gruppe (die Aufstellung von Mission 16) erreicht im Abendlicht die Berge, der Sack läuft hinterher. Die Frischlinge brechen aus dem Hinterhalt hinter der Gruppe vorbei, schnappen den Sack und sind in einer Staubwolke so schnell weg, wie sie kamen. Untertitel für die Sprüche („Hehe, da isser! Der dicke blaue Sack!“, „Tschüss, ihr alten Fossile! Nich’ hauen!“, der Sack ruft hinterher). Klick oder Leertaste überspringt.
- **Danach:** Gespräch mit den Stimmen der Gruppe (`voiced: true` in der Mission), dann das **Lager** (`camp_after: true`, ohne Händler), dann Mission 18.
- **Händler:** Der Sack ist ab hier weg. Im Lager gibt es keinen Händler (die Händlerseite fehlt, das Lager beginnt bei „Ausrüstung“), bis **Morgrim** nach Mission 19 mit der Gruppe zieht und eine Truhe mit Waren aus besseren Tagen verkauft. Umsetzung: `data/shop.json` mit `merchants` (id, Name, Porträt, Sprüche, `from`/`until` = Kapitel der Party im Lager; Sack bis 16, Morgrim ab 20) und `for` an den Waren (Standard `sack`); `Party.merchant()`, `Party.stock()`, `Camp`. Morgrims Truhe: Runenschwert, Mithrilhemd, Sternenstab, Runenrobe, Drachenzahn (je 1) sowie Heiltrank, Gegengift und Äther, alles etwas teurer als beim Sack. Abschlussgespräch in `story_ch19.json`.
- **Test:** `tests/test_zwischenspiel.gd`.

## Mission 18: Die Wölfe der Nacht (`ch18`, neues Biom Schnee)
- **Neues Biom Schnee** (Kartenfeld `biome: "schnee"`, `mood: "nacht_schnee"`): Bodenshader mit Schnee und hartem Firn, zugefrorenes Wasser (heller Eis-Shader), Felswände links, rechts und oben (`walls`), Sprites **Schneefichten** (zwei Sorten), **Eisfelsen** und **Schneehaufen** (Gemini). Es ist Nacht: helles Mondlicht auf dem Schnee, kühler Filter und **Schneefall** (`Battle._build_snowfall`, runde weiche Flocken, Dichte folgt der Grafikoption „Partikel“).
- **Einleitung (nur Dialog):** Die Gruppe erreicht das Gebirge. **Wendy verteilt warme Kleidung** an alle (ein Dialog), **Stachelia beschwert sich** über die Kälte (und nimmt den Pullover mit Flügellöchern „nur weil mir kalt ist“). Nach beschwerlichem Aufstieg bricht die Nacht an, Heulen ist zu hören.
- **Gegner:** fünf **Wölfe** (`wolf`, 20 Leben, Angriff 8, Bewegung 5) und ein **schneeweiße Alphawölfin** (`alphawolf`, weiblich, größer, 42 Leben, Kehlbiss mit Gift, Heulen). Gegnerfaktor ×1,7 (nicht gemessen).
- **Zwei Wege:** (1) **Kampf:** Rudel besiegen wie üblich. (2) **Vertreiben:** Wölfe sind **scheu** (Tag `scheu`): Bekommt ein Wolf **Angst** (Hundsfreunds **Bellen**, Miras **Bärengebrüll**), läuft er **sofort davon** (Popup „Angst!“, zählt nicht als besiegt, kein Nemesis). Die **Alphawölfin ist mutig** (Tag `mutig`, „Furchtlos“) und lässt sich nicht erschrecken. Sind **alle** normalen Wölfe weg, **bevor einer fällt**, schließt sich die Alphawölfin an (Mission gewonnen, `kills_max`). Die Hinweise sind dezent: Wendy sagt nur „Die armen Wölfe. Wenn man sie nur vertreiben könnte …“, und nach dem ersten davongelaufenen Wolf kommt ein knapper Kommentar des Hundes. Fällt vorher ein Wolf, geht es nur noch im Kampf.
- **Neue Bausteine für Missionen:** Auslöser `all_frightened` (alle dieser Arten wurden schon einmal erschreckt, in Mission 18 nicht mehr genutzt), Bedingungen `kills_max` und `kills_min`, Schritte `retreat_all` (alle Gegner dieser Arten ziehen ab), `recruit` (Verbündeter wird für die Zukunft gewonnen, `Party.recruited`) und `win` (friedlicher Sieg, Bonusziel `friedlich`).
- **Alphawölfin als Held** (Anzeigename „Alphawölfin“, Kennung `alphawolf`; Karten-Figur etwas kleiner, `size` 1,7): Figur mit `recruit_only: true`, erst ab Mission 19 und nur wählbar, wenn sie sich angeschlossen hat (`Party.roster`). Zwei Fähigkeiten: **Kehlbiss** (×1,6 und Gift 3 Runden) und **Heulen** (Verbündete +2 Angriff, Feinde im Umkreis 3 kurz Angst). Porträts neutral, lachend, wütend und Karten-Figur von Gemini.
- **Bonus:** „Kein Held fällt“ (110 Gold), „Das Rudel friedlich vertrieben“ (2 Heilhonig).
- **Test:** `tests/test_woelfe.gd`.

## Wetter und Stimmung der Missionen 1 bis 9 (2026-11-04)
Alle frühen Karten haben jetzt Tageszeit, Licht und Wetter. Neue Karten-Felder: `mood` (Lichtstimmung, Presets in `Battle.LIGHT_PRESETS`) und **`weather`** (Liste, `Battle._build_weather`). Die Dichte aller Partikel folgt der Grafikoption „Partikel und Regen“.

| Mission | Stimmung (`mood`) | Wetter (`weather`) |
|---|---|---|
| 1 Eichenfurt | `morgen`: warmes Morgenlicht (ohne Dunstfilter) | `pollen` (goldene Schwebeteilchen) |
| 2 Hohlweg | `bewoelkt`: grau, gedämpft | `drizzle` (feiner Nieselregen) |
| 3 Mühlbach | `daemmerung`: Abendrot in Orange | `embers` (Funkenflug), `smoke` (Rauchschwaden) |
| 4 Teehaus am Pass | `morgennebel`: kühle Morgenstimmung | `fog` (Nebelschwaden) |
| 5 Stachelias Rückkehr | `sommer`: goldener Nachmittag | `pollen`, `petals` (Blütenblätter) |
| 6 Möwenbucht | `hafen`: früher Abend am Meer (klare Sicht) | `rain` (leichter Regen, kein Nebel) |
| 7 Sandhafen | Wüsten-Filter | `sand` (Flugsand in Streifen) |
| 8 Oase | Wüsten-Filter | `sandstorm` (dichter Flugsand), Staubwolke bei Robinas Auftritt (`dust: true` im `spawn`) |
| 9 Festung | `duester` | `ash` (Ascheflocken), `lightning_far` (fernes Wetterleuchten mit leisem Grollen) |

Weitere Wetter-Namen für neue Karten: `rain`, `pollen`, `petals`, `embers`, `smoke`, `drizzle`, `fog`, `mist`, `sand`, `sandstorm`, `ash`, `lightning_far`; Stimmungen: `morgen`, `bewoelkt`, `daemmerung`, `morgennebel`, `sommer`, `hafen` (dazu die älteren `sumpf`, `nacht`, `nacht_regen`, `gewitter`, `nacht_schnee`, `duester`). Alles lässt sich an der Karte kombinieren, ohne Code.

- **Weniger Dunst (Spieltest 2026-11-04):** Mission 1 ohne Dunstfilter, Mission 6 mit Regen statt Nebel bei klarer Sicht; der Umgebungsnebel der Presets `bewoelkt` und `daemmerung` wurde halbiert, nur Mission 4 (Morgennebel) und der Sumpf bleiben bewusst neblig.

- **Mission 1, Bienen (2026-11-04):** Stachelias Bienen sind in Mission 1 noch nicht etabliert gewesen. Ein Büttel wurde durch **zwei Bienenkrieger** ersetzt (bei Stachelia im Nordosten, `map_ch1.json`), und Stachelia ruft sie in ihrer ersten Begegnung mit Mira („Meine Bienen, schnappt ihn euch!“). So kennt der Spieler sie vor Mission 5. Der Simulator rechnet Mission 1 weiter mit der Karte, die Werte der beiden Bienen (12 Leben, Angriff 5) sind etwas schwächer als der entfernte Büttel zusammen.

## Mission 19: Der Regent im Schnee (`ch19`, Schnee-Biom, 2026-11-04)
- **Übergang:** Vor der Mission läuft die **Zwischensequenz im Schneesturm** (`interlude_before: {scene: "snow", title: "Der Regent im Schnee"}`, nur die Titelkarte ohne Kapitelzeile, `SnowTrek`, **16 Sekunden**, die **gewählte Truppe** stapft einen Pass hinauf, Windrauschen, **Linksklick oder Taste bricht ab** (kurze Schwarzblende), **Schwarzblende auch danach**, dann blendet die nächste Szene aus Schwarz auf). Danach Einleitung (Mira, Hundsfreund), Gruppenwahl, Kampf.
- **Karte:** `map_ch18.json`, Nacht-Schnee mit Nebel, **keine Feinde zu Beginn**, links am Rand eine **schäbige Hütte** (Objekt `huette`, Sprite `fx_huette`, Gemini). Die Gruppe startet **nah an der Hütte** (links unten in der Mitte): Schon im ersten Zug erreicht ein Held den Auslöser (Abstand 5), es muss niemand lange laufen, bevor etwas passiert.
- **Ablauf:** Nähert sich ein Held der Hütte (**Auslöser `near_object`**: `{id: "huette", dist: 5}`), tritt der **Regent in Lumpen** heraus (Einheit `fuerst_lumpen`, Team der Spieler als **Schützling**, 30 Leben, Verteidigung 2, Bilder neutral und weinerlich, Chibi, Gemini). Er friert und ist verängstigt: „Ihr Narren! Ihr habt sie zu mir geführt!“ Dann erscheinen **Robowart** (Cyborg-Wart, mit Staubwolke) und **die Frischlinge** (eine Figur, wie in den anderen Missionen) oben rechts von der Gruppe (nur wenige Felder entfernt, sie sind schon im zweiten Zug da): „Der Meister hat entschieden: Der Regent verstummt. Und ihr gleich mit.“
- **Ziel:** Neuer Zieltyp **`rout_spawned`** (wie „alle Gegner besiegen“, aber erst nach dem ersten Auftauchen von Gegnern, sonst wäre die Mission ohne Feinde sofort gewonnen). Vorher: „Seht nach, wer in der Hütte wohnt“, danach: „Beschützt den Regenten, besiegt alle Gegner (n übrig)“. **Fällt der Regent, ist die Mission verloren** (neues Kartenfeld **`lose_if_fallen`**).
- **Gegner:** Cyborg-Wart (flieht bei Niederlage mit Rückzugszeile) und Frischlinge, Faktoren ×1,5 (`progression.json`, 6 Punkte, Ausrüstung 3,5), nicht mit dem Simulator gemessen.
- **Neue Bausteine:** `near_object` (Editor: „Die Gruppe nähert sich einem Objekt“), `rout_spawned`, `lose_if_fallen`, Szene `snow` im Zwischenbild. Test: `tests/test_regent_schnee.gd`. Bild der Karte: `SHOT=kap SHOT_CH=ch18`.

## Mission 20: Hogsmeat (`ch20`)
- **Übergang:** Nach dem Kampf gegen den Regenten berichtet Morgrim vor dem Lager von der geheimen Basis des Meisters im flammenden Berg der Vorsehung. Die Gruppe vermisst den entführten Sack als Freund und hofft, in Hogsmeat etwas über ihn zu erfahren. Im Lager handelt Morgrim; anschließend folgt die normale Gruppenwahl.
- **Geschichte:** In Hogsmeat verplappern sich die Frischlinge: Sie haben den Sack zum Meister auf den Berg gebracht. Die Gruppe zieht weiter, um ihren Freund zurückzuholen; die Rettung steht noch aus.
- **Übergang zum Vulkanbiom:** Nach dem Lager reist die dort gewählte Gruppe durch ein dunkles Vulkangebirge mit einem abgestorbenen Baum. Die überspringbare 3D-Sequenz nutzt die Gruppen- und Kamerafahrt der Schneereise; ein animierter 2D-Noise-Shader erzeugt Staub an den Füßen der laufenden Figuren. Stachelia fliegt ohne Fußstaub. Hinter dem freigegebenen Berg-Sprite ziehen freigegebene Aschewolken; ihre roten Reflexe und die Feuer- und Lavafarben flackern dezent per Shader. Eine spielbare Vulkanmission gibt es noch nicht.
- **Karte und Ziel:** Ein düsteres, bergiges Walddorf mit Wildschwein-Hütten, ohne Regen. Ein Lagerfeuer aus bestehenden 2D-Sprites beleuchtet die Landschaft mit flackerndem 3D-Punktlicht. Die Gruppe soll alle Gegner besiegen; Robowart und die Frischlinge ziehen sich bei ihrer Niederlage zurück.
- **Gegner:** Drei Wildschwein-Krieger mit Schildwall, zwei Speerwerfer mit Reichweite 2–3 und die Frischlinge. Erst wenn die Frischlinge nach ihrer Niederlage geflohen sind, erscheint Robowart als Verstärkung. Die Einheiten und Dorfgebäude verwenden freigegebene eigene Grafiken.
- **Gruppe:** Die zuletzt für Mission 19 gewählte Gruppe ist die Vorgabe. Die eigene Auswahl für Mission 20 hat danach Vorrang; feste Dialogfiguren bleiben erhalten.
- **Balance:** Gegnerfaktoren ×2,0 für Leben und Angriff. Robowarts späterer Auftritt soll die Anfangsphase entschärfen; frühere Simulationsergebnisse mit Robowart von Beginn an sind nicht auf diese Aufstellung übertragbar. Die tatsächliche Schwierigkeit sollte im Spiel nachgeprüft werden.
- **Prüfung:** `tests/test_hogsmeat_data.gd` prüft Missionsdaten, Karte, Gruppenübernahme und Grafiken; `tests/test_hogsmeat_battle.gd` prüft Kampf, Rückzüge, Sieg und Spielstand.

## Mission 22: Die Zwergenmine (`ch22`, Vulkan-Biom, 2026-11-08)
- **Lage:** Am Fuß des Vulkans hat Wart (Cyborg-Wart) einen Stollen in den Berg treiben lassen. Drei versklavte **Zwerge** mit Spitzhacken stehen gefesselt im Westen (0, 5), Osten (11, 5) und Norden (8, 1) (Weltobjekte `hostage`, Bilder `tokens/zwerg_alt`, `zwerg_jung`, `zwerg_kraeftig`, Gemini). Wart steht vor dem Stolleneingang (Deko `fx_stollen`, Gemini).
- **Ziel `free_all`:** nur Befreien gewinnt. Befreien dauert hier **einen Zug** (neues Objektfeld `"steps": 1`; ohne das Feld bleiben es zwei Schritte wie in Mission 4 und 13) und geht nur ohne Wache daneben.
- **Wart** ist **unangreifbar und untätig** (neue Kartenfelder für Gegner `"idle": true`, `"untouchable": true`, letzteres setzt die Marke `unantastbar`).
- **Wellen:** Ist eine Welle besiegt (nur noch Wart da), schickt er die nächste. Neuer Auslöser-Schalter `"repeat": true` (feuert jedes Mal neu) und neuer Schritt `"waves"`: vier Wellen aus Hogsmeat-Kriegern, -Speerwerfern und Soldaten des Regenten (je 3 bis 4), reihum, mit Warts Ruf als Popup. Beim ersten Wellenende ein kurzer Spruch von Wart.
- **Werte:** wie Mission 21 (Gegnerfaktor 2,0). Der Simulator kennt `free_all` nicht, Balancing erst nach dem Anspielen.
- **Test:** `tests/test_ch22.gd`.

## Mission 23: Zwischenspiel „Im Labor des Professors“ (`ch23`, neues Biom Basis, 2026-11-08)
- **Inhalt:** Xiùlán ist allein in die Basis der Feinde eingebrochen und schleicht durch das Labor von Professor Kugelblitz. Unterwegs belauscht sie in fünf Teilen ein Gespräch zwischen dem Professor und einem **Schatten** (Sprecher `schatten`, Name „???“, Porträt `schatten.png` = per Skript geschwärztes Sack-Porträt). Der Professor nennt ihn „Sohn“ und hat Angst vor ihm, der Schatten befiehlt, mit den Experimenten weiterzumachen. Am Professor angekommen taucht **Maja** auf und schlägt Xiùlán für die Demütigung ihres Bruders k.o.
- **Spielweise:** feste Gruppe (nur Xiùlán), kein Kampf. Neues Kartenfeld **`hide_steps`**: Liste von Schritten mit je 1–2 Versteckfeldern hinter Geräten; beim Auswählen sind nur die Felder des nächsten Schritts erreichbar (golden, Hinweis „Versteck wählen“). Neuer Auslöser **`{"hide_step": n}`** (Versteck n erreicht). Ziel `reach` (Feld vor dem Professor, eigener Zieltext über `text`). Der Professor ist `idle` und `untouchable`.
- **Abschlussszene** (`when: victory`): Dialog, Maja erscheint (`spawn`), neuer Schritt **`knockout`** (BONK, Sterne, Figur kippt um und wird grau, „Zzz“; `fall`: left/right), dann „Bringt sie in den Käfig“ und neuer Schritt **`blackout`** (Schwarzblende in Sekunden). Danach bleibt das Bild schwarz, die Mission endet ohne Abschlussgespräch (leere `outro` wird übersprungen).
- **Keine Belohnung:** neues Missionsfeld **`no_rewards`** (kein Belohnungs- und Aufstiegsbildschirm). `Progression.missions_done_before` zählt jetzt aus den Missionsdaten: `stub` und `no_rewards` zählen nicht als Kampfmission.
- **Biom „Basis“** (Schurkenbasis wie bei James Bond): Bodenshader-Schalter `base_floor` (Metallplatten mit Fugen und Nieten, einige Fugen leuchten cyan, rote Warnstreifen am Rand, Metallwände ringsum), flacher Boden ohne Pflanzen und Steine, Lichtstimmung `basis` (kaltes Neonlicht), Deko-Feld `light` für farbige Punktlichter. Neue Geräte (Gemini): `fx_konsole`, `fx_reaktor`, `fx_serverschrank`, `fx_roboterarm`, `fx_monitorwand`; als Deckung dienen Weltobjekte vom neuen Typ **`geraet`** (Bild über `look`) und die Glasbehälter.
- **Aufnahme:** `SHOT=cutscene SHOT_SCENE=labor` spielt die Mission selbsttätig ab (Dialoge schalten nach 1,4 s weiter, `Dialogue.auto_advance`).
- **Test:** `tests/test_ch23.gd`.

## Mission 24: Das leere Labor (`ch24`, Biom Basis, 2026-11-08)
- **Lage:** Die Zwerge haben verraten, dass der Minenschacht in die Basis führt. Die Gruppe kommt im Labor aus Mission 23 an (dieselbe Karte, Gruppe startet im Süden), doch Professor, Maja und Xiùlán sind fort.
- **Ablauf:** Nähert sich ein Held dem mittleren Behälter (`near_object` `geraet_z2`, Abstand 3), platzen drei Behälter und drei **Robo-Frischlinge** springen heraus, jetzt jeder eine eigene Figur (knuddelige Frischlinge mit kleinen Cyborg-Implantaten und Spielzeug-Elementarwaffen: `frischling_feuer`, `frischling_blitz`, `frischling_eis`, je 24 Leben, Angriff 8; im Gespräch eigenes Dreierbild `frischlinge_robo` mit `_lachend`/`_wuetend`, Sprechername „Robo-Frischlinge“). Sind alle drei besiegt (`enemies_left: 0`, nur wenn die Behälter geplatzt sind), steigt **Robo-Wart** auf (`cyborg_wart`, `no_flee`). Ziel `defeat` Robo-Wart. **Abgang (Abschlussszene `victory`):** Wart und die drei Robo-Frischlinge rappeln sich dort auf, wo Wart fiel (Spawn mit `"near": "cyborg_wart"` statt `pos` = letzte Position dieser Figur), Wart hat genug vom Verlieren („Angeln vielleicht“) und zieht mit seinen Frischlingen für immer ab (`retreat_all`, `retreat`). Danach treten Wart und die Frischlinge in der Geschichte nicht mehr auf.
- **Elementarkanonen** (Reichweite 2–3, Abklingzeit 2): **Flammenkanone** (×1,1, Ziel brennt 2 Runden, Feuerball mit Rauchspur und Explosion), **Blitzkanone** (×1,0, springt mit 50 % auf Nachbarn über, zackiger Doppelstrahl, Blitzbild, Wackeln), **Frostkanone** (×0,9, neuer Status **„Unterkühlt“**: Bewegung −2, Verteidigung −1 für 2 Runden; frostblauer Strahl, Schneestaub und Eisblock).
- **Ziel `defeat` geändert:** zählt nur, wenn die Figur schon auf dem Feld war (sonst wäre die Mission ohne Robo-Wart sofort gewonnen).
- **Abschluss:** Die Gruppe findet ein Gebiss: Xiùlán war hier, und nicht freiwillig.
- **Test:** `tests/test_ch24.gd`.

## Mission 25: Der Thronsaal (`ch25`, Finale, neues Biom Thronsaal, 2026-11-08)
- **Biom „Thronsaal“** (`biome`/`mood` `thronsaal`): Boden wie „Basis“, dazu Fugen in dunklem Gold, violettes Leuchten und ein roter Samtteppich mit Goldborte (Kartenfeld `carpet`: [x0, y0, x1, y1]). Thron als Deko `fx_thron` mit neuem Deko-Feld `back` (nach Norden versetzt, damit die Figur davor sitzt).
- **Ausgangslage:** Professor Kugelblitz sitzt auf dem Thron (`idle`, `untouchable`), Maja, Oskar und sechs Soldaten bewachen ihn (`guard`), zwei weitere Soldaten stehen auf dem Weg zur Honigmaschine an der Ostwand.
- **Käfige:** Geiseln (`hostage`) mit eigenem Bild über `look` (`fx_kaefig_sack`, `fx_kaefig_xiulan`, Figur ins Käfigbild eingesetzt). Neue Objektfelder: `locked` (nicht befreibar, „Käfig verschlossen“) und `replace` (Käfig verschwindet beim Öffnen bzw. Aufbrechen, die Figur steht danach als Einheit da).
- **Honigmaschine** (neuer Objekttyp `honigmaschine`, Zustände `empty`/`filled`, Bilder `fx_honigmaschine`, `fx_honigmaschine_voll`): Menüpunkt „Honig einfüllen“ nur für Stachelia auf einem Nachbarfeld (Weltwirkung `fill`). Stachelia ist Pflicht (Story-Zeile im Intro).
- **Enthüllung** (`when: {"object": {"id": "honigmaschine", "state": "filled"}}`): Der Sack lacht, der Professor flieht (`retreat`), der Käfig des Sacks bricht auf, der Sack (`sack_boss`, 80 Leben (im Spiel ×2,0 = 160), Angriff 8 (im Spiel 16), `no_flee`) erscheint auf dem Thron (`"near": "kugelblitz"`), neuer Schritt `{"unguard": [ids]}` schickt die Wachen los.
- **Der Sack:** „Spitze Sachen“ (`wurfmesser`, Fernwurf ×1,1, Reichweite 2–4, 40 % auf Nachbarn) und „Trank aus dem Beutel“ (`trankwurf`, heilt Verbündete um 16, Reichweite 1–4). Neue Porträts `sack_boss` (lachend, wütend) und Spielfigur.
- **Xiùlán:** Käfig in zwei Runden öffnen, dann kämpft sie als Gast (`xiulan_gast`, Spieler steuert sie) mit halbem Leben (Spawn-Feld `hp_ratio`).
- **Sieg:** alle Gegner besiegt (`rout`); Maja und Oskar fliehen bei wenig Leben wie bisher. Abschluss mit offenem Ende (Professor entkommen, Brumm hat eine neue Spur). Simulator: rechnet ab dem Honig (Sack auf dem Thron, Professor nicht dabei).
- **Nachbesserung (Nutzer: zu schwer):** Maja und Oskar fliehen schon bei 30 % Leben (neues Missionsfeld `flee_below`: {id: Anteil}, auch im Simulator). Neuer Schritt `{"beam": {"from": Objekt, "to": Objekt}}`: gewaltiger goldener Energiestrahl (Aufladen, pulsierender Strahl mit Funken, Einschlag mit Lichtblitz), in der Enthüllung von der Honigmaschine zum Käfig des Sacks. Simulator danach: Ø 85 % (schwächste Gruppen um 56 %).

## Kapitel 26: Epilog „Heimkehr“ (`ch26`, ohne Kampf, 2026-11-08)
- **Ablauf:** Kein Standbild. Aufblende, dann eine **flache Kamerafahrt** (Kartenfeld `dialog_cam: "waisenhaus"`, Missionsfeld `flight`: 8 Sekunden) vom Teich auf die Gruppe vor dem Waisenhaus zu (Karte `map_ch26` nach Mission 14, Stimmung Sommer, `no_markers`: keine Ringe und Blickpfeile unter den Figuren). Danach das Gespräch, dann **Schwarzblende mit „Für Elisabeth“** (Missionsfeld `dedication`), die Schrift blendet langsam aus, zurück zum Hauptmenü.
- **Aufstellung:** Vor der Tür der Hundsfreund mit Lotte, Mia und Pip, seitlich am Haus Bianca, Morgrim, Mira und die Alphawölfin, links und rechts die übrigen Helden, Robina und Stachelia außen.
- **Gespräch:** Feste Zeilen (die Kinder stürmen dem Hundsfreund entgegen, Lotte, Bianca mit der Suppe, Morgrim im alten Aussehen, freundlich mit Schürze und Kochlöffel, der im Waisenhaus helfen will, Schlusszeilen von Mira und Hundsfreund). Dazu **vier zufällige Heldenzeilen** (Missionsfeld `random_pick`, Zeilen mit Feld `group`; `Mission.pick_groups`), Stachelias grummeliger Wortwechsel ist eine der möglichen Gruppen. Die Kinder schauen überall fröhlich.
- **Testmenü:** „Finale: Sieg über den Sack (bis zum Schluss)“ startet Mission 25 direkt vor dem letzten Schlag. Aufnahme: `SHOT=cutscene SHOT_SCENE=epilog`.

## Kapitelgrenzen und Level-Einleitungen (2026-11-09)
- **Drei Kapitel:** Kapitel 1 „Der Regent“ (Missionen 1 bis 9), Kapitel 2 „Die Suche nach der wahren Gefahr“ (ab dem Reisebild `ch10`), **Kapitel 3 „Der flammende Berg“** ab dem Überfall am Pass (`ch17`, Kapitelzeile in der Bergszene, Titel in der Kapitelwahl).
- **Filmische Level-Einleitung** (Missionsfeld `intro_flight`: `from`, `to`, `height`, `fov`, `seconds`): Die Kamera fliegt vor dem Kampf flach von hinter der Gruppe über das Feld auf die Gegner zu, mit Kinobalken; Klick oder Taste überspringt, beim Direktstart ohne Einleitung entfällt sie. Eingesetzt in Hogsmeat (`ch20`), Zwergenmine (`ch22`) und Thronsaal (`ch25`). Ansehen: `SHOT=flight SHOT_CH=ch25`.
- **Kampfverlauf:** Der Kampf merkt sich zu Beginn jeder Spielerrunde Leben der Gruppe und Zahl der Gegner (`Battle.history`); der Statistik-Bildschirm zeigt den Verlauf als Grafik (`HistoryChart`), und jede Mission schreibt ihre Werte als JSON nach `user://statistik/` (nicht im Headless-Betrieb).
- **Lichtstimmungen nachgetragen (2026-11-09):** Mission 7 „morgen“ (Wüstenmorgen: tiefe rosig-goldene Sonne, lange Schatten), Mission 8 „mittagshitze“ (Sonne fast senkrecht, ausgebleichte Farben, starkes Flimmern), Mission 9 bleibt „duester“ (Abend). In der Wüste stecken diese Stimmungen im Wüstenlicht (`Battle._apply_desert_light`), damit kein zweiter Farbfilter darüberliegt. Mission 11 „morgen“ (Morgensonne), Mission 12 „mittag“ (Mittagslicht, neue Stimmung), Mission 14 „abend“ (Abendstimmung, neue Stimmung). Damit hat jede Karte eine eigene Stimmung.
- **Mission 8, Übernahme als Aktion (2026-11-09):** Robina wird nicht mehr durch bloßes Danebenstehen übernommen (das verstand niemand), sondern wie beim Befreien über einen Menüpunkt: Robo neben dem Panzer wählt **„Umprogrammieren (n/3)“**, höchstens einmal pro Runde; der Fortschritt bleibt, auch wenn Robina wegfährt. Zielfelder `action: true`, `by: "robo"`; Zieltext, Briefing und Robos Satz erklären es. Der Simulator rechnet die Übernahme weiter vereinfacht (Held drei Runden daneben). Fällt Robo vorher, ist die Mission verloren (`lose_if_fallen: "robo"`, im Briefing und Zieltext genannt).
- **Mission 12, mehr Lösungen für den Hebel (2026-11-09):** Der Knochenwurf des Hundsfreunds reicht jetzt 1 bis 3 Felder (vorher 2) und trifft den Hebel vom Westufer aus (Feld vor der Brücke, sobald der Bogenschütze dort besiegt ist). Robinas Breitseite (Reichweite 3 bis 9) konnte es schon von vielen Feldern aus. Der Brückenhebel hat das Objektfeld `reach_bonus: 1`: Fernfähigkeiten treffen ihn aus einem Feld mehr Abstand, so erreichen Elisabeths Kanone und der Knochenwurf ihn von mehreren Feldern am Westufer, auch solange der Bogenschütze am Ufer steht (der Hebel im Hohlweg, Mission 2, bleibt unverändert). Das Briefing nennt die Lösungen. Test: `tests/test_bruecke_loesungen.gd`.
- **Mission 12, über den Fluss ohne Brücke (2026-11-09):** Muskelaugusts Wurf trägt einen Helden ans Ostufer (Landefelder bis 4 Felder weit), und Lins Stabsprung führt jetzt über die **hochgezogene Brücke** (Objekt `bridge` mit `active: "up"`, Lösung `leap: "pass"`, wie bei der Mauer). Test: `tests/test_fluss_ueberqueren.gd`.
- **Mission 13 leichter (2026-11-09):** Kinder in einer Runde befreit (`steps: 1`), ein Infanterist und ein Bogenschütze weniger (Nutzer: zu hart, besonders wenn Wart zurückkommt). Gegner zu Beginn: Professor, Frischlinge, je ein Infanterist, Bogenschütze, Priester und Reiter.
- **Professor Kugelblitz weniger zäh (2026-11-09):** 38 statt 55 Grundleben, im Spiel also etwa 65 (Mission 13) und 68 (Mission 16) statt 94 und 99.
- **Cyborg-Wart entschärft (2026-11-10):** Er schoss in Mission 13 schwächere Helden mit einer Rakete um (31 bis 39 Schaden gegen 22 bis 30 Leben). Jetzt: eigener Raketenwerfer `cyborg_rakete` (×1,1 statt ×1,6, Nachbarn 40 % statt 50 %; der normale Wart behält `rakete`), Angriff 11 statt 13, und die **Computer-Analyse kostet die Aktion** (die Gegner-KI greift danach im selben Zug nicht mehr an). In Mission 13 trifft die Rakete Wendy oder Stachelia jetzt für etwa 18 von 22 Leben. Gilt in allen Missionen mit Cyborg-Wart (13, 15, 19, 20, 22, 24).
- **Kein Sofort-K.-o. aus vollen Leben (2026-11-10):** Ein Held mit vollen Leben übersteht jeden einzelnen Gegnertreffer mit 1 Leben („Knapp überlebt!“, `Battle._spare_full_hp`, ebenso im Simulator). Gegner haben diesen Schutz nicht. Anlass: Xiùláns Gebiss und andere Fähigkeiten warfen leichte Helden mit einem Treffer um. Zusätzlich hat der Professor einen eigenen Laser `kugelblitz_laser` (×1,3, ignoriert 30 % Verteidigung), und Warts `rakete` macht ×1,3. Test: `tests/test_kein_sofort_ko.gd`.
- **Professor angreifbarer, Mira stärker (2026-11-10):** Der Professor hat Vert 2 und Res 2 statt 4 und 5. Mira hat Grundangriff 5 statt 3. Voll ausgerüstet trifft Mira ihn in Mission 16 von vorn für 11 statt 6, mit der Sternschnuppe für 14 statt 8. Wendy trifft ihn für 9 statt 6.
- **Mission 16, Lohn-Gespräch:** Die Zeilen in Runde 4 („Und wo bleibt mein Lohn, Professor?!“) zeigen jetzt den Professor links und Xiùlán rechts, statt Ser Albrecht, der oft gar nicht dabei ist.
- **Heiler +10 % (2026-11-10):** Gruppenheilung (Wendy) 7 statt 6, Sternensegen (Mira) 8 statt 7, Wundersalbe (Quacksalber) 15 statt 14. Die Talent-Ränge rechnen auf den neuen Grundwert.
- **Mission überspringen (2026-11-10):** Ab der zweiten Niederlage in einer Mission zeigt der Niederlage-Bildschirm zusätzlich „Mission überspringen“ (`Main.SKIP_AFTER_DEFEATS`). Dann laufen auf frischem Schlachtfeld die Abschlussszenen (`"when": {"victory": true}`, `Battle.skip_to_victory`), danach geht es weiter wie nach einem Sieg: Belohnungsbild „Übersprungen“ mit der festen Missionsbelohnung und Stufe, aber ohne Bonusziele und Statistik, dann Abschlussdialog und Lager. Test: `tests/test_mission_skip.gd`.

## Bonusziele mit eigener Art und zusätzliche Truhen (2026-11-10)
Ein Bonusziel (`objectives` in der Karte) kann neben `id` ein Feld **`kind`** tragen. Dann ist die `id` frei wählbar (sie muss je Mission eindeutig sein, die Chronik merkt sich erfüllte Ziele darüber), und `kind` bestimmt die Prüfung in `Battle.results`. Ohne `kind` gilt wie bisher die `id`.

| `kind` | Erfüllt, wenn | Felder |
|---|---|---|
| `taktik` | so viele Treffer mit Positionsbonus (Rücken, Flanke, Höhe, Hinterhalt) | `count` |
| `ruecken` | Gegner mit einem Treffer in den Rücken besiegt | `count` oder `unit` (ein bestimmter Gegner) |
| `zuerst` | dieser Gegner fällt oder flieht als erster | `unit` |
| `faehigkeit` | so viele Gegner mit einer Fähigkeit besiegt | `count` |
| `ohne_traenke` | kein Gegenstand aus dem Rucksack benutzt | – |
| `truhen` | alle Truhen geöffnet und Dörfer besucht | – |

Die Zähler dafür führt `Battle.feats`. In diesen Missionen ersetzt ein solches Ziel „In X Runden gewonnen“ (Belohnung unverändert): 1 (drei Positions-Treffer), 2 und 20 (beide Truhen), 7 (Oskar von hinten), 8 (ohne Gegenstände), 9 (drei Gegner mit Fähigkeiten), 12 (sechs Positions-Treffer), 15 (drei Gegner von hinten). Das Rundenziel bleibt, wo Zeitdruck zur Mission gehört (3, 6, 19, 22, 24, 25).

**Neue Truhen abseits des Wegs** (nur Verbrauchsgegenstände, kein Gold, damit die Zielkurve des Goldes bleibt): Mission 6 (1,9), 7 (0,3), 8 (0,1), 9 (1,1), 12 (11,9), 15 (0,4), 18 (11,5). Nicht gespielt und nicht im Simulator gemessen; Lage und Inhalt bei Bedarf in `map_chN.json` ändern.

## Vorgeschichten der Figuren (2026-11-13)
Tester fanden es unbefriedigend, dass viele Figuren ohne Vorgeschichte in der Gruppe stehen. Deshalb stellen sich die Figuren jetzt bei ihrem ersten Auftritt vor:
- **Mission 1:** Wendy (Heilerin des Dorfs), Brunhilde (Brauerin), Meister Lin (bringt den Kindern Teekochen bei), Ser Albrecht (Ritter im Ruhestand) und Käpt'n Elisabeth (ihr Schiff liegt zum Flicken in der Möwenbucht).
- **Mission 2:** Robo ist der Gruppe seit Eichenfurt gefolgt. Er ist in einem Bach aufgewacht und erinnert sich an nichts davor.
- **Mission 3, Abschluss:** Mira fragt Takeda nach seiner Herkunft, danach läuft die Rückblende.
- **Mission 4:** Die Kage-Schwestern tauchen auf dem Dach auf („Ihr seid die mit der Teekanne!“).

## Rückblende: Takeda und die Kage-Schwestern (`rb_takeda`, neues Biom fernost)
- **Geschichte:** Hanakaze, eine Hafenstadt weit hinter dem Meer, in der Nacht des Laternenfests. Takeda ist Leibwächter des Fürsten und stellt die Kage-Schwestern, die die Jadeteekanne des Fürsten gestohlen haben. Dann kommt die Stadtwache, und die Teekanne ist im Gerangel zerbrochen. Die drei fliehen gemeinsam auf Elisabeths Rostige Möwe. Elisabeth setzt sie in der Möwenbucht ab, seitdem muss sie ihr Schiff flicken (Mission 1).
- **Ablauf:** Missionsfeld `flashback` in Mission 3. Nach dem Abschlussgespräch kommen eine Textkarte („Rückblende“), die Einleitung und der Kampf. Danach folgt das Abschlussgespräch auf See (`outro_at_sea`, dieselbe Szene wie nach Mission 6), eine Textkarte („Zurück in Mühlbach“) und das Gespräch `after` (Mira und Takeda in der Gegenwart). Erst dann geht es ins Lager vor Mission 4. Die Rückblende ist **kein eigenes Kapitel** (Kapitelzählung, Spielstand und Chronik bleiben unverändert), sie gibt keine Belohnung und keinen Aufstieg. Mit „Direkt in den Kampf“ für Mission 3 wird sie übersprungen.
- **Kampf:** Takeda allein gegen die Kage-Schwestern (Gegner-Einheit `kage_gegner`, flieht statt zu fallen). Wendepunkt bei weniger als 60 % Leben der Schwestern, spätestens in Runde 3 oder wenn sie fliehen: Die Stadtwache kommt (9 × `stadtwache`, davon 4 am Hafen), die Schwestern wechseln die Seite, Elisabeth erscheint am Steg mit der Breitseite. Neues Ziel: **Takeda** muss den Steg erreichen (alle drei Steg-Felder sind golden, Ziel `reach` mit `tiles`).
- **Neue Technik:** Schritt **`goal`** (neues Missionsziel während des Kampfs, `reach` markiert das Feld), Schritt **`side`** (`{"id": "kage_gegner", "become": "ninjas"}`: Gegner verschwindet im Rauch, an derselben Stelle steht die Heldenfigur auf unserer Seite), Ziel `reach` mit `unit` (nur diese Figur zählt), Objektfeld `size` (Sondergröße des Haus-Sprites, Pagode), Deko-Effekt `lantern` (warmes Punktlicht).
- **Biom fernost:** Häuser `fx_haus_fernost1..2`, Dorfplatz `fx_dorf_fernost`, Kirschbäume `fx_kirschbaum1..2` statt Eichen, Deko `fx_pagode`, `fx_torii`, `fx_laterne`, Wetter `petals`, Stimmung `daemmerung`. Eigene Kampfmusik (Missionsfeld `battle_music`): `rueckblende_jpop.mp3`, J-Pop-Instrumental im Stil eines Anime-Vorspanns, mit Gemini erzeugt (`tools/gemini/music.mjs`, Original in `strategie/musik/`), Stille am Anfang und Ende für die Schleife abgeschnitten. Sprites per Gemini (`tools/gemini/run.mjs`, Abschnitt „Rückblende Takeda“).
- **Testmenü:** Knopf „Rückblende: Takeda und die Kage-Schwestern“ (danach Mission 4 mit Einleitung). Direktstart: `START_FLASHBACK=rb_takeda`. Test: `tests/test_rueckblende.gd`.
- Der Dialog-Editor zeigt nur `ch*`-Missionen. Die Texte der Rückblende stehen in `game/data/story_rb_takeda.json` und `missions/rb_takeda.json`.
