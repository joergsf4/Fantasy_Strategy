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
- **Fähigkeits-Ränge** (`Talents.ranked`, aus den vorhandenen Daten abgeleitet, keine neuen Animationen, **keine Abklingzeit-Änderung**: das war zu stark, siehe Nutzerhinweis 2026-11-03): Rang 1: Wirkung +20 % (Schaden, Heilung; ohne beides +1 Runde Statusdauer). Rang 2: Reichweite +1 oder Umkreis +1 (sonst +1 Runde Statusdauer, sonst +10 % Wirkung). Rang 3: nochmals +20 % Wirkung. Die Anzeige sagt, was der nächste Rang bringt (z. B. „Schaden ×1,8 → ×2,16“). Fähigkeiten, die auch Gegner dieser Mission nutzen (z. B. der rote Laser bei Kugelblitz), werden nicht verändert.
- **Neue Fähigkeiten beim Aufsteigen** wären der nächste Ausbau, sind aber für ein kleines Projekt zu groß und stehen nicht an.
- **Simulator:** Zellen mit `points` verteilen die Punkte nach der Standardverteilung (Leben, Fähigkeit 1, Angriff, Fähigkeit 2 der Reihe nach, `Talents.default_allocation`).
- **Tests:** `tests/test_aufstieg.gd`.

## Messung (Stand mit Wirkung statt Abklingzeit)
`docs/balance_kurve.md`: Mit den erwarteten Punkten (0 bis 3) und Ausrüstungen erreicht die Zielquote bei Mission 3 etwa ×1,45, Mission 5 ×1,6, Mission 6 ×1,45, Mission 7 ×1,7, Mission 8 ×1,35 und Mission 12 über ×2,5 (Brücke ab Runde 4). Eingestellt sind 1,2 / 1,5 / 1,5 / 1,7 / 1,3 / 2,0 für Mission 3, 5, 6, 7, 8, 12, dazu 1,5 für Mission 9 und 1,7 für Mission 13 (vom Simulator nicht gemessen). Das liegt etwas unter der Zielquote, damit es nicht zu hart wird. Erst im Spiel prüfen, dann nachstellen.

## Teststart mit üblicher Ausstattung
`START_CH=ch14 godot --path game` (optional `START_SKIP=1`) startet direkt in einer Mission und gibt allen Helden das, was dort üblich wäre (`Party.for_chapter`): Talentpunkte nach der Standardverteilung (Leben, Fähigkeit 1, Angriff, Fähigkeit 2), Ausrüstung nach der Zielkurve (`gear_tier` der Mission, `Progression.gear_for`), 400 Gold und Vorräte (4 Heiltränke, 2 Gegengift, 2 Äther, 1 Rauchbombe). Der Teststart wird nie gespeichert (`Party.test_run`), der echte Spielstand bleibt unberührt.

## 5. Story und Fluff in Gesprächen
- Jede Dialogzeile kann `"story": true` tragen. Im Text-Editor gibt es dafür pro Gespräch die Checkbox **„Story relevant“** (setzt das Flag für alle Zeilen des Gesprächs, ein blaues „Story“-Abzeichen steht im Kopf).
- `Mission.dialogue_ids` zählt nur Story-Zeilen. **Nur Figuren aus Story-Gesprächen sind in der Gruppenwahl fest vorgegeben**, alle anderen Plätze sind frei tauschbar. (Kapitel mit `fixed_squad` bleiben komplett fest.)
- Story sind Einleitungen und Abschlüsse, Auftritte und Rückzüge der Gegenspieler, Beitritte, Wendepunkte. Alles andere (Sprüche zu Fähigkeiten, Wetter, Hitze, Nebengeplänkel) ist Fluff.
- Pro Mission (1–9, 12–17) gibt es für jeden wählbaren Helden ohne Story-Rolle einen **albernen Fluff-Spruch** (Auslöser: Runde 2 bis 6, nur wenn der Held in der Gruppe ist, Notiz „Fluff: <Held>“). So bekommt jeder Held, der mitkommt, ein paar Worte.
- Fest vorgegeben sind damit je Mission nur noch 2 bis 5 von 6 Plätzen (vorher meist 4 bis 6).

## 6. Stimmen: Story-Zeilen für wechselnde Figuren
- Eine Dialogzeile kann `"voices": [{"id", "text", "expr"?}, …]` tragen (nach Vorrang). Die Zeile selbst ist die **Rückfallstimme** (meist Mira) und spricht immer. Ist ein Held aus der Liste in der Gruppe, spricht der erste davon an ihrer Stelle, mit eigenem Text und Gesichtsausdruck (`Mission.voiced`, angewendet bei Einleitung, Abschluss und Kampfgesprächen).
- Fest vorgegeben sind nur noch Rückfallstimme und Gegenüber der Zeile, nicht die Stimmen. Im Text-Editor hängt unter jeder Zeile ein Bereich „Stimmen“ (Figur wählen, Text, Ausdruck, Vorrang ↑↓, entfernen).
- Beispiel: Mission 3 (nur noch Mira und Dr. Humbug fest). Die Einleitung läuft vor der Gruppenwahl, dort zählt die zuletzt gewählte Gruppe (sonst die Vorgabe der Karte).
