# Fortschritt über die Kapitel

Wie die Gruppe stärker wird und wie die Gegner mitwachsen. Vier Schichten, Stand 2026-11-03 (Heldenstufen durch Talentpunkte ersetzt).

## 1. Zielkurve (`game/data/progression.json`)
Je Mission: erwartete **Talentpunkte** (`points`) und **Ausrüstungsstufe** (`gear_tier`, Durchschnitt über Waffe, Rüstung, Talisman), **Zielsiegquote** (`target_win`: 97 % am Anfang, 85 % gegen Ende) und die **Gegnerfaktoren** (`enemy_hp`, `enemy_atk`). Die Faktoren werden im Kampf auf alle Gegner der Karte angewendet (`Battle._spawn`, `Progression.enemy_scale`); 1,0 lässt eine Mission unverändert. Gemessen wird mit dem Simulator: `python3 tools/balance.py e16` schreibt `docs/balance_kurve.md` (Siegquote je Mission bei Gegnerfaktor 1,0 bis 2,5, mit den erwarteten Talentpunkten und Ausrüstung).
- **Ergebnis der Messung:** Mit den erwarteten Stufen und Ausrüstungen sind die Missionen 3 bis 7 deutlich zu leicht (Zielquote erst bei etwa ×1,8 bis ×2,2). Die Faktoren im Spiel sind **bewusst vorsichtig** gesetzt (1,0 bis 1,5 für Mission 1 bis 9, 1,8 für Mission 12, 1,6 für Mission 13), bis wir es im Spiel gespielt haben. Danach schrittweise anheben.
- **Grenzen:** Der Simulator kennt Mission 2 (Mauer), Mission 4, 9, 11 und 13 nicht (Zielquote dort geschätzt). Mission 12 wird mit Brücke ab Runde 4 gerechnet.

## 2. Ausrüstung in vier Stufen
`items.json`: jedes Stück hat `tier` 1 bis 4 und `price`. Stufe 1: Eisenschwert, Lederwams, Kettenhemd, Windstiefel, Kristallstab, Magierrobe, Heilkraut, Fernrohr. Stufe 2: Stahlklinge, Schwere Axt, Plattenpanzer, Arkanstab, Rubinring, Zauberlampe. Stufe 3: Meisterklinge, Schuppenpanzer, Seidenrobe, Sturmstiefel, Smaragdring. Stufe 4: Runenschwert, Mithrilhemd, Sternenstab, Runenrobe, Drachenzahn.
- **Sortiment je Kapitel** (`shop.json`, Feld `stock`): jede Ware hat `from` (ab diesem Kapitel) und optional `until`. Neues kommt nach und nach, Altes läuft aus. Der bisherige Fehler: es gab nur ein festes „Kapitel 1“-Sortiment.
- **Preise steigen mit der Stufe** (Stufe 1 etwa 25 bis 90 Gold, Stufe 4 etwa 360 bis 420 Gold). Eine Mission bringt etwa 150 bis 400 Gold, also reicht das Geld nicht für alles auf einmal, und das ist gewollt.
- **Verkaufen:** Lagerstücke gehen im Händler-Reiter für den halben Preis zurück (`Party.sell`). Die Liste im Händler scrollt, weil das Sortiment wächst.

## 3. Gegner wachsen auf mehreren Wegen
Nicht nur durch Zahlen: Faktoren je Mission (siehe 1.), neue Gegnertypen (Frischlinge, Professor Kugelblitz, Cyborg-Wart mit Computer-Analyse), Begleiter und Mechaniken (Maschine, Zugbrücke, Feuer, Bienenkörbe, Zugbrücke, Brücke). Auch die Schwierigkeitsstufen (`difficulty.json`) multiplizieren später darauf.

## 4. Stufen und Talentpunkte (ersetzt die festen Heldenstufen)
Feste Stufen mit wachsenden Zahlen brachten keinen Spielspaß, deshalb gibt es Talentpunkte, die man selbst verteilt (Entscheidung des Nutzers, 2026-11-03):
- **Stufe:** Die Gruppe steigt mit jeder geschafften Kampfmission um eine Stufe (`Party.level()`, Stufe 1 am Anfang). **Alle 3 Stufen gibt es einen Talentpunkt** (`Party.points_for`, `levels_per_point` in `progression.json`): nach 12 Missionen also 4 Punkte. Das ist wenig und soll es sein: Wer Robos roten Laser auf Rang 3 bringt, hat fast alles ausgegeben.
- **Nur wer dabei ist:** Verteilt wird nur für Helden der Mission-Gruppe. Nach dem **Statistikbildschirm** erscheint der **Aufstiegs-Bildschirm** (`TalentScreen`), sobald für einen Helden der Gruppe ein Punkt frei ist; die **fröhliche Siegmusik läuft dabei weiter**. Kommt in der nächsten Mission ein Held neu in die Gruppe (oder hat er Punkte offen), wird er **vor Beginn der Mission** aufgelevelt (derselbe Bildschirm, nach der Gruppenwahl). So muss niemand für alle Helden Punkte verteilen: wer nicht mitkämpft, spart sich das, und wer später dazukommt, hat dieselbe Punktzahl und verteilt dann (`Party.needs_prompt`, `prompted`). Alle Helden sind trotzdem gleich: die Punktzahl hängt nur von der Gruppenstufe ab, nicht vom Einsatz.
- **Verteilen:** Je Held vier Felder mit Rang 0 bis 3: **Leben** (+4 je Rang), **Angriff** (+1 je Rang), **Fähigkeit 1** und **Fähigkeit 2**. Punkte lassen sich zurückholen und neu verteilen (`TalentPanel`, auch im Lager-Reiter „Talente“, dort nur für die Gruppe).
- **Fähigkeits-Ränge** (`Talents.ranked`, aus den vorhandenen Daten abgeleitet, keine neuen Animationen): Rang 1: Abklingzeit −1. Rang 2: Wirkung +25 % (Schaden, Heilung, Dauer; sonst noch −1 Abklingzeit). Rang 3: Reichweite oder Umkreis +1 (sonst nochmals +15 % Wirkung). Die Anzeige sagt, was der nächste Rang bringt. Fähigkeiten, die auch Gegner dieser Mission nutzen (z. B. der rote Laser bei Kugelblitz), werden nicht verändert.
- **Neue Fähigkeiten beim Aufsteigen** wären der nächste Ausbau, sind aber für ein kleines Projekt zu groß und stehen nicht an.
- **Simulator:** Zellen mit `points` verteilen die Punkte nach der Standardverteilung (Leben, Fähigkeit 1, Angriff, Fähigkeit 2 der Reihe nach, `Talents.default_allocation`).
- **Tests:** `tests/test_aufstieg.gd`.

## Messung (Stand mit Punkt alle 3 Stufen)
`docs/balance_kurve.md`: Mit den erwarteten Punkten (0 bis 3) und Ausrüstungen erreicht die Zielquote bei Mission 3 etwa ×1,45, Mission 5 ×1,7, Mission 6 ×1,45, Mission 7 ×1,5, Mission 8 ×1,25 und Mission 12 etwa ×1,9 (Brücke ab Runde 4). Die eingestellten Faktoren (Mission 3: 1,2, Mission 5: 1,5, Mission 6 und 7: 1,5, Mission 8: 1,3, Mission 12: 1,8) liegen damit nahe an der Zielquote, etwas darunter, damit es nicht zu hart wird. Mission 9, 11 und 13 kennt der Simulator nicht (geschätzt). Erst im Spiel prüfen, dann nachstellen.
