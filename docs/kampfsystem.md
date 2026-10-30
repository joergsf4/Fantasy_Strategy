# Kampfsystem (Stand: Phase 1+2)

Rundenbasiert auf dem Raster. Pro Runde zieht erst der Spieler mit all seinen Figuren, dann die Gegner.

## Zugablauf einer Figur
1. **Bewegen** (blaue Felder, Geländekosten, Gegner blockieren, Wasser nur für Flieger).
2. **Eine Aktion** im Menü neben der Figur: **Angriff**, **Heilen**, **Fähigkeit**, **Gegenstand**, **Verteidigen** oder **Warten**.
   *Stabsprung* verbraucht die Aktion nicht. Rechtsklick nimmt den Zug zurück.

## Schaden (immer vorhersehbar, kein Zufall)
`Angriff × Fähigkeitsfaktor × (1 + Positionsbonus) − Verteidigung − Deckung`, mindestens 1.
- Magie zählt gegen **RES**, Körperangriffe gegen **DEF**.
- **Rücken +30 %**, **Flanke +15 %** (die Blickrichtung zeigt der kleine Pfeil auf dem Ring der Figur).
  Eine Figur blickt in die Richtung ihrer letzten Bewegung bzw. ihres letzten Angriffs.
- **Höhe +15 %**, wenn der Angreifer deutlich höher steht (Hügel, Berg).
- **Deckung**: Wald +1, Dorf +1, Berg +2, Burg +2.
- **Hinterhalt +30 %** beim ersten Angriff aus dem Versteck.
- Vor jedem Angriff zeigt die Vorschau Schaden, Boni und den Gegenschlag.

## Gegenschlag
Nur nach einem normalen **Angriff**, wenn der Verteidiger überlebt, nicht benommen ist und der Angreifer in seiner Reichweite steht. Bogenschützen (Reichweite 2–3) kontern im Nahkampf nicht. **Fähigkeiten lösen keinen Gegenschlag aus.**

## Status
| Status | Wirkung |
|---|---|
| Spott / Wütend | muss den Auslöser angreifen, wenn erreichbar, sonst zu ihm laufen |
| Gift | 3, 4, 5 Schaden zu Beginn der eigenen Phase. **Jede Heilung entfernt es** |
| Benommen | setzt die nächste Phase aus, kein Gegenschlag |
| Verborgen | nicht angreifbar; endet beim Angriff oder nach 2 Runden |
| Gestärkt | +ATK/+DEF |
| Erschöpft | −2 DEF |
| Verwandelt | nur normale Soldaten, 3 Runden aus dem Spiel |

## Abklingzeit
Jede Fähigkeit hat eine Abklingzeit in Runden (steht im Menü, z. B. „Todeswirbel (2)“). Sie sinkt zu Beginn der eigenen Phase.

## Fähigkeiten
| Figur | Fähigkeit | Wirkung | AK |
|---|---|---|--:|
| Mira & Brumm | Bärenpranke | ×1,3, Ziel greift 2 Runden Mira an | 3 |
| Ser Albrecht | Schlachtruf | Umkreis 2: +3 ATK/+2 DEF, 2 Runden | 4 |
| | Verspotten | Gegner im Umkreis 3 müssen ihn angreifen | 4 |
| Takeda | Todeswirbel | 8 Nachbarfelder ×1,6, danach erschöpft | 3 |
| Meister Lin | Stabsprung | über Gegner springen (×0,6), frei | 2 |
| Kage-Schwestern | Versteck | 2 Runden unsichtbar, Hinterhalt +30 % | 4 |
| Käpt’n Elisabeth | Kanone | Reichweite 2–3, ×1,5, Nachbarn des Ziels 50 % | 3 |
| Muskelaugust | Wurf | Gegner 4 Felder in zufällige Richtung, benommen | 4 |
| Robo | Roter Laser | Reichweite 2–4, ×1,8, ignoriert 50 % DEF | 3 |
| | Grüner Laser | heilt 12, entfernt Gift, Reichweite 1–3 | 2 |
| Blauer Hundsfreund | Knochenwurf | Reichweite 1–2, 3 × ×0,5 | 2 |
| Wendy Wolle | Heilen | 8 HP, entfernt Gift (Aktion „Heilen“, ohne Abklingzeit) | – |
| | Gruppenheilung | Umkreis 1 um ein Ziel, 6 HP, entfernt Gift | 3 |
| Claude | Polymorph | normale Einheit 3 Runden aus dem Spiel | 5 |
| Stachelia | Giftstachel | ×0,8 + Gift | 2 |
| Brunhilde Bräu | Fasswurf | Reichweite 1–3, ×0,9, Ziel wütend auf sie | 3 |

**Passive:** Infanterie *Schildwall* (+1 DEF neben anderer Infanterie), Berittene *Sturmangriff* (+1 Schaden je gerade gelaufenem Feld, max. +3).

Die Daten stehen in `game/data/units.json` und `game/data/abilities.json`, die Regeln in `game/scripts/combat.gd` und `game/scripts/status.gd`.

## Ausrüstung und Gegenstände (Stand: Phase 3)

Daten: `game/data/items.json`, Regeln: `game/scripts/items.gd` (gemeinsam für Spiel und Simulation).

### Ausrüstung
Drei Plätze: **Waffe, Rüstung, Talisman**. Pro Platz zählt ein Stück. Die Werte gelten ab Kampfbeginn und stehen auf der Figurenkarte.

| Stück | Platz | Wirkung |
|---|---|---|
| Eisenschwert | Waffe | +2 Angriff |
| Schwere Axt | Waffe | +4 Angriff, −1 Bewegung |
| Kristallstab | Waffe | +3 Angriff (nur Magier) |
| Lederwams | Rüstung | +1 Verteidigung, +4 Leben |
| Kettenhemd | Rüstung | +2 Verteidigung |
| Plattenpanzer | Rüstung | +4 Verteidigung, −1 Bewegung |
| Magierrobe | Rüstung | +3 Magieresistenz |
| Windstiefel | Talisman | +1 Bewegung |
| Heilkraut-Amulett | Talisman | +8 Leben |
| Fernrohr | Talisman | +1 Reichweite (nur Fernkämpfer) |
| Zauberlampe | Talisman | Fähigkeiten laden 1 Runde schneller (mindestens 1) |
| Rubinring | Talisman | +1 Angriff, +1 Verteidigung |

### Rucksack (Verbrauchsgegenstände)
Der Rucksack gehört dem ganzen Team. Einen Gegenstand zu benutzen **kostet die Aktion** der Figur. Ziel: Nachbar oder man selbst.

| Gegenstand | Wirkung |
|---|---|
| Heiltrank | heilt 12 Leben |
| Gegengift | entfernt Gift, heilt 3 |
| Äther | setzt alle Abklingzeiten des Ziels zurück (der „Mana-Trank“ dieses Spiels) |
| Rauchbombe | Ziel und Nachbarn 2 Runden verborgen |
| Bier | heilt 5, +3 Angriff, −1 Verteidigung (2 Runden) |

Startausstattung Kapitel 1 (`loadout_chapter1`): 2 Heiltränke, 1 Gegengift, 1 Äther; Ausrüstung für sechs Helden.
Im Kampf: Menü **Gegenstand** neben **Angriff / Fähigkeit / Warten**. Nicht benutzbare Einträge sind grau (z. B. Äther, wenn keine Abklingzeit läuft).

### Balancing
`tools/balance.py e5` misst den Wert jedes Stücks als Siegquoten-Gewinn und in Infanteristen-Punkten; siehe `docs/balance.md`, Abschnitt „Gegenstände und Ausrüstung“.


## Beute, Lager und Händler (Stand: Phase 2 und 3)

- **Quellen (alle fest, kein Zufall):** Truhen („Truhe öffnen“) und Dörfer („Dorf besuchen“) auf der Karte kosten die Aktion und gehen einmal; Gegner mit Beutesack über dem Kopf geben ihren Gegenstand beim Besiegen; Kapitelbelohnung und Bonusziele (Kein Held fällt, schnell gewonnen) nach dem Sieg.
- **Gold** nur aus diesen Quellen. Zutaten: Kraut, Hopfen, Kristall.
- **Lager** nach jedem Kapitel (`game/scripts/camp.gd`): **Händler** (Hase „Hoppel“, fester Vorrat pro Kapitel, `data/shop.json`; Preise noch Platzhalter bis zum Balancing-Lauf E5), **Brauen** (`data/recipes.json`: Brunhilde braut Bier, Wendy Heiltrank und Gegengift, Claude Äther), **Ausrüstung**, **Aufstellung**.
- **Speichern:** `user://save.json` (Gold, Rucksack, Zutaten, Ausrüstung, Vorrat des Händlers).


## Verteidigen
Neue Aktion im Menü (wie Angriff oder Warten, der Zug der Figur endet):
- bis zur nächsten eigenen Phase **halber Schaden** (aufgerundet, mindestens 1), **Tanks nur ×0,4**;
- **kein Gegenschlag** (wer verteidigt, schlägt nicht zurück);
- wirkt zusammen mit Deckung (Wald, Berg, Burg), der Mindestschaden 1 bleibt;
- sichtbar als blaue Schutzblase um die Figur und „Verteidigt 1“ auf der Karte.

Der **Stabsprung** verbraucht die Aktion nicht: Springen und danach Verteidigen geht, damit ein Ablenker hinter den feindlichen Linien überlebt. Messwerte und das Zusammenspiel mit Spott stehen in `docs/balance.md`, Abschnitt 7.


## Gegenspieler-Fähigkeiten
| Figur | Fähigkeit | Wirkung | AK |
|---|---|---|--:|
| Wart | Raketenwerfer | Reichweite 2–4, ×1,6, Nachbarn des Ziels 50 % | 3 |
| Oskar | Feldherrenbefehl | Verbündete im Umkreis 3: +3 ATK, +2 DEF, 2 Runden | 4 |
| Maja | Eisiger Blick | Helden im Umkreis 2: −3 ATK, −1 DEF, 2 Runden (Status „Eingeschüchtert“) | 3 |

Fähigkeiten auf sich selbst (Befehl, Blick) setzt die Gegner-KI ein, wenn genug Ziele im Umkreis sind (`ai_self` in `abilities.json`).
