
## 16. Gruppenvielfalt je Mission (E17)

`python3 tools/balance.py e17`. Je Mission bis zu 60 zufällige, regelkonforme Gruppen: die **festen Story-Plätze** bleiben, der Rest kommt aus allen bis dahin bekannten Helden. Jede Gruppe kämpft 16-mal mit den erwarteten **Talentpunkten** und der erwarteten **Ausrüstung** gegen die Gegner der Karte (Faktoren aus `progression.json`). Gemessen mit der Simulations-KI; Sonderziele (Tor in Mission 2, Geisel in 4, Kinder befreien in 13, Feuer in 14, Wolfsangst in 17) kennt sie nicht, dort zählt „alle Gegner besiegt“. Nicht gemessen: Missionen 2, 4, 11, 13.

| Mission | feste Plätze | Gruppen | Ziel | Ø Siegquote | schlechteste 10 % der Gruppen | schlechteste Gruppe | Gruppen unter Ziel−15 % |
|---|---|--:|--:|--:|--:|--:|--:|
| 18 | Mira & Brumm, Blauer Hundsfreund, Stachelia | 60 | 85% | 100% | 100% | 100% | 0 (0%) |
| 19 | Mira & Brumm, Blauer Hundsfreund | 60 | 85% | 99% | 91% | 81% | 0 (0%) |
| 20 | Mira & Brumm | 60 | 85% | 98% | 80% | 38% | 2 (3%) |
| 21 | Mira & Brumm, Die Kage-Schwestern | 60 | 85% | 100% | 100% | 100% | 0 (0%) |

### Schlechteste Gruppen je Mission

- **Mission 18:** 100%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Brunhilde Bräu, Käpt’n Elisabeth, Muskelaugust; 100%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Brunhilde Bräu, Käpt’n Elisabeth, Robo; 100%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Brunhilde Bräu, Meister Lin, Lumi Sternenglanz
- **Mission 19:** 81%: Mira & Brumm, Blauer Hundsfreund, Lumi Sternenglanz, Die Kage-Schwestern, Dr. Humbug, Wendy Wolle; 88%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Meister Lin, Dr. Humbug, Wendy Wolle; 94%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Käpt’n Elisabeth, Die Kage-Schwestern, Wendy Wolle
- **Mission 20:** 38%: Mira & Brumm, Stachelia, Lumi Sternenglanz, Die Kage-Schwestern, Dr. Humbug, Wendy Wolle; 56%: Mira & Brumm, Stachelia, Lumi Sternenglanz, Die Kage-Schwestern, Ser Albrecht, Wendy Wolle; 94%: Mira & Brumm, Stachelia, Käpt’n Elisabeth, Muskelaugust, Robo, Wendy Wolle
- **Mission 21:** 100%: Mira & Brumm, Die Kage-Schwestern, Stachelia, Brunhilde Bräu; 100%: Mira & Brumm, Die Kage-Schwestern, Stachelia, Blauer Hundsfreund; 100%: Mira & Brumm, Die Kage-Schwestern, Stachelia, Lumi Sternenglanz

### Beitrag der Helden (Siegquote der Gruppen mit dem Helden minus Durchschnitt, in Prozentpunkten)

| Held | M18 | M19 | M20 | M21 |
|---|--:|--:|--:|--:|
| Blauer Hundsfreund | +0 | +0 | +2 | +0 |
| Brunhilde Bräu | +0 | +1 | +2 | +0 |
| Die Kage-Schwestern | +0 | -1 | -3 | +0 |
| Dr. Humbug | +0 | -1 | -1 | +0 |
| Käpt’n Elisabeth | +0 | +0 | +2 | +0 |
| Lumi Sternenglanz | +0 | -0 | -3 | +0 |
| Meister Lin | +0 | -1 | +2 | +0 |
| Mira & Brumm | +0 | +0 | +0 | +0 |
| Muskelaugust | +0 | +0 | +2 | +0 |
| Robina | +0 | +1 | +2 | +0 |
| Robo | +0 | +1 | +2 | +0 |
| Ser Albrecht | +0 | +1 | -0 | +0 |
| Stachelia | +0 | +0 | -5 | +0 |
| Takeda | +0 | +0 | +2 | +0 |
| Wendy Wolle | +0 | -3 | -3 | – |
