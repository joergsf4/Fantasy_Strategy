# Fortschritt über die Kapitel

Wie die Gruppe stärker wird und wie die Gegner mitwachsen. Vier Schichten, Stand 2026-11-03.

## 1. Zielkurve (`game/data/progression.json`)
Je Mission: erwartete **Heldenstufe** (`level`) und **Ausrüstungsstufe** (`gear_tier`, Durchschnitt über Waffe, Rüstung, Talisman), **Zielsiegquote** (`target_win`: 97 % am Anfang, 85 % gegen Ende) und die **Gegnerfaktoren** (`enemy_hp`, `enemy_atk`). Die Faktoren werden im Kampf auf alle Gegner der Karte angewendet (`Battle._spawn`, `Progression.enemy_scale`); 1,0 lässt eine Mission unverändert. Gemessen wird mit dem Simulator: `python3 tools/balance.py e16` schreibt `docs/balance_kurve.md` (Siegquote je Mission bei Gegnerfaktor 1,0 bis 2,5, mit der erwarteten Stufe und Ausrüstung).
- **Ergebnis der Messung:** Mit den erwarteten Stufen und Ausrüstungen sind die Missionen 3 bis 7 deutlich zu leicht (Zielquote erst bei etwa ×1,8 bis ×2,2). Die Faktoren im Spiel sind **bewusst vorsichtig** gesetzt (1,0 bis 1,5 für Mission 1 bis 9, 1,8 für Mission 12, 1,6 für Mission 13), bis wir es im Spiel gespielt haben. Danach schrittweise anheben.
- **Grenzen:** Der Simulator kennt Mission 2 (Mauer), Mission 4, 9, 11 und 13 nicht (Zielquote dort geschätzt). Mission 12 wird mit Brücke ab Runde 4 gerechnet.

## 2. Ausrüstung in vier Stufen
`items.json`: jedes Stück hat `tier` 1 bis 4 und `price`. Stufe 1: Eisenschwert, Lederwams, Kettenhemd, Windstiefel, Kristallstab, Magierrobe, Heilkraut, Fernrohr. Stufe 2: Stahlklinge, Schwere Axt, Plattenpanzer, Arkanstab, Rubinring, Zauberlampe. Stufe 3: Meisterklinge, Schuppenpanzer, Seidenrobe, Sturmstiefel, Smaragdring. Stufe 4: Runenschwert, Mithrilhemd, Sternenstab, Runenrobe, Drachenzahn.
- **Sortiment je Kapitel** (`shop.json`, Feld `stock`): jede Ware hat `from` (ab diesem Kapitel) und optional `until`. Neues kommt nach und nach, Altes läuft aus. Der bisherige Fehler: es gab nur ein festes „Kapitel 1“-Sortiment.
- **Preise steigen mit der Stufe** (Stufe 1 etwa 25 bis 90 Gold, Stufe 4 etwa 360 bis 420 Gold). Eine Mission bringt etwa 150 bis 400 Gold, also reicht das Geld nicht für alles auf einmal, und das ist gewollt.
- **Verkaufen:** Lagerstücke gehen im Händler-Reiter für den halben Preis zurück (`Party.sell`). Die Liste im Händler scrollt, weil das Sortiment wächst.

## 3. Gegner wachsen auf mehreren Wegen
Nicht nur durch Zahlen: Faktoren je Mission (siehe 1.), neue Gegnertypen (Frischlinge, Professor Kugelblitz, Cyborg-Wart mit Computer-Analyse), Begleiter und Mechaniken (Maschine, Zugbrücke, Feuer, Bienenkörbe, Zugbrücke, Brücke). Auch die Schwierigkeitsstufen (`difficulty.json`) multiplizieren später darauf.

## 4. Heldenstufen
**Geplante Änderung (Entscheidung des Nutzers, später):** alle Helden leveln gleich, egal ob dabei (siehe Backlog). Aktueller Stand: Erfahrung (`Party.xp`, gespeichert): pro geschaffter Mission **12 EP für jeden Helden der Gruppe, 6 für wartende Helden**. Schwellen für Stufe 2 bis 5: 20, 50, 90, 140 EP. Stufenbonus (`Progression.bonus`): Stufe 2 +3 Leben, Stufe 3 +1 Angriff, Stufe 4 +3 Leben und +1 Verteidigung (Magier: Magieresistenz), Stufe 5 +1 Angriff und +3 Leben; Heiler bekommen zusätzlich +1 Heilung auf Stufe 3 und 5. Die Stufe zeigt der Ausrüstungs-Reiter im Lager, der Belohnungsbildschirm meldet „Stufenaufstieg!“. Der Simulator rechnet Stufen mit (`level` je Zelle). Nach 13 Missionen sind Helden, die immer dabei waren, auf Stufe 4, Stufe 5 folgt mit den nächsten Missionen.
- **Tests:** `tests/test_aufstieg.gd`.
