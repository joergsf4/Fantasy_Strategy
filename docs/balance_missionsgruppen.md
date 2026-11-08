
## 16. Gruppenvielfalt je Mission (E17)

`python3 tools/balance.py e17`. Je Mission bis zu 60 zufällige, regelkonforme Gruppen: die **festen Story-Plätze** bleiben, der Rest kommt aus allen bis dahin bekannten Helden. Jede Gruppe kämpft 16-mal mit den erwarteten **Talentpunkten** und der erwarteten **Ausrüstung** gegen die Gegner der Karte (Faktoren aus `progression.json`). Gemessen mit der Simulations-KI; Sonderziele (Tor in Mission 2, Geisel in 4, Kinder befreien in 13, Feuer in 14, Wolfsangst in 17) kennt sie nicht, dort zählt „alle Gegner besiegt“. Nicht gemessen: Missionen 2, 4, 11, 13.

| Mission | feste Plätze | Gruppen | Ziel | Ø Siegquote | schlechteste 10 % der Gruppen | schlechteste Gruppe | Gruppen unter Ziel−15 % |
|---|---|--:|--:|--:|--:|--:|--:|
| 1 | Mira & Brumm | 1 | 97% | 100% | 100% | 100% | 0 (0%) |
| 3 | Mira & Brumm, Dr. Humbug | 60 | 95% | 100% | 100% | 100% | 0 (0%) |
| 5 | Mira & Brumm | 60 | 92% | 100% | 100% | 100% | 0 (0%) |
| 6 | Blauer Hundsfreund, Mira & Brumm | 60 | 92% | 98% | 81% | 62% | 2 (3%) |
| 7 | Mira & Brumm, Lumi Sternenglanz | 60 | 92% | 100% | 100% | 100% | 0 (0%) |
| 8 | Robo, Mira & Brumm | 60 | 90% | 94% | 77% | 69% | 1 (2%) |
| 9 | Mira & Brumm | 60 | 90% | 100% | 100% | 100% | 0 (0%) |
| 12 | Blauer Hundsfreund | 60 | 85% | 100% | 100% | 100% | 0 (0%) |
| 14 | Mira & Brumm, Blauer Hundsfreund | 60 | 85% | 100% | 100% | 100% | 0 (0%) |
| 15 | Mira & Brumm, Blauer Hundsfreund, Stachelia | 60 | 85% | 98% | 84% | 75% | 0 (0%) |
| 16 | Mira & Brumm, Blauer Hundsfreund, Stachelia | 60 | 85% | 98% | 90% | 81% | 0 (0%) |
| 17 | Mira & Brumm, Blauer Hundsfreund, Stachelia | 60 | 85% | 100% | 100% | 100% | 0 (0%) |

### Schlechteste Gruppen je Mission

- **Mission 1:** 100%: Mira & Brumm, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Ser Albrecht, Wendy Wolle
- **Mission 3:** 100%: Mira & Brumm, Dr. Humbug, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Muskelaugust; 100%: Mira & Brumm, Dr. Humbug, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Ser Albrecht; 100%: Mira & Brumm, Dr. Humbug, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Robo
- **Mission 5:** 100%: Mira & Brumm, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Muskelaugust, Die Kage-Schwestern; 100%: Mira & Brumm, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Muskelaugust, Robo; 100%: Mira & Brumm, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Die Kage-Schwestern, Takeda
- **Mission 6:** 62%: Blauer Hundsfreund, Mira & Brumm, Meister Lin, Muskelaugust, Die Kage-Schwestern, Wendy Wolle; 62%: Blauer Hundsfreund, Mira & Brumm, Meister Lin, Die Kage-Schwestern, Ser Albrecht, Wendy Wolle; 81%: Blauer Hundsfreund, Mira & Brumm, Muskelaugust, Die Kage-Schwestern, Ser Albrecht, Wendy Wolle
- **Mission 7:** 100%: Mira & Brumm, Lumi Sternenglanz, Brunhilde Bräu, Käpt’n Elisabeth, Blauer Hundsfreund, Ser Albrecht; 100%: Mira & Brumm, Lumi Sternenglanz, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Muskelaugust; 100%: Mira & Brumm, Lumi Sternenglanz, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Ser Albrecht
- **Mission 8:** 69%: Robo, Mira & Brumm, Meister Lin, Muskelaugust, Die Kage-Schwestern, Dr. Humbug; 75%: Robo, Mira & Brumm, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Die Kage-Schwestern; 75%: Robo, Mira & Brumm, Brunhilde Bräu, Meister Lin, Die Kage-Schwestern, Takeda
- **Mission 9:** 100%: Mira & Brumm, Brunhilde Bräu, Käpt’n Elisabeth, Blauer Hundsfreund, Meister Lin, Dr. Humbug; 100%: Mira & Brumm, Brunhilde Bräu, Käpt’n Elisabeth, Blauer Hundsfreund, Meister Lin, Ser Albrecht; 100%: Mira & Brumm, Brunhilde Bräu, Käpt’n Elisabeth, Blauer Hundsfreund, Dr. Humbug, Takeda
- **Mission 12:** 100%: Blauer Hundsfreund, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Muskelaugust, Dr. Humbug; 100%: Blauer Hundsfreund, Brunhilde Bräu, Käpt’n Elisabeth, Meister Lin, Die Kage-Schwestern, Dr. Humbug; 100%: Blauer Hundsfreund, Brunhilde Bräu, Käpt’n Elisabeth, Mira & Brumm, Dr. Humbug, Takeda
- **Mission 14:** 100%: Mira & Brumm, Blauer Hundsfreund, Brunhilde Bräu, Käpt’n Elisabeth, Die Kage-Schwestern; 100%: Mira & Brumm, Blauer Hundsfreund, Brunhilde Bräu, Käpt’n Elisabeth, Robina; 100%: Mira & Brumm, Blauer Hundsfreund, Brunhilde Bräu, Käpt’n Elisabeth, Ser Albrecht
- **Mission 15:** 75%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Meister Lin, Lumi Sternenglanz, Dr. Humbug; 81%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Brunhilde Bräu, Dr. Humbug, Wendy Wolle; 88%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Brunhilde Bräu, Lumi Sternenglanz, Dr. Humbug
- **Mission 16:** 81%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Lumi Sternenglanz, Muskelaugust, Dr. Humbug; 81%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Dr. Humbug, Ser Albrecht, Wendy Wolle; 94%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Brunhilde Bräu, Lumi Sternenglanz, Wendy Wolle
- **Mission 18:** 100%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Brunhilde Bräu, Käpt’n Elisabeth, Die Kage-Schwestern; 100%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Brunhilde Bräu, Käpt’n Elisabeth, Robina; 100%: Mira & Brumm, Blauer Hundsfreund, Stachelia, Brunhilde Bräu, Meister Lin, Takeda

### Beitrag der Helden (Siegquote der Gruppen mit dem Helden minus Durchschnitt, in Prozentpunkten)

| Held | M1 | M3 | M5 | M6 | M7 | M8 | M9 | M12 | M14 | M15 | M16 | M18 |
|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| Blauer Hundsfreund |  |  |  | +0 | +0 | +3 | +0 | +0 | +0 | +0 | +0 | +0 |
| Brunhilde Bräu | – | +0 | +0 | +1 | +0 | -1 | +0 | +0 | +0 | -1 | +1 | +0 |
| Die Kage-Schwestern |  |  | +0 | -3 | +0 | -2 | +0 | +0 | +0 | +1 | +1 | +0 |
| Dr. Humbug |  | +0 | +0 | +1 | +0 | +0 | +0 | +0 | +0 | -5 | -2 | +0 |
| Käpt’n Elisabeth | – | +0 | +0 | +2 | +0 | +1 | +0 | +0 | +0 | +0 | +0 | +0 |
| Lumi Sternenglanz |  |  |  |  | +0 | +3 | +0 | +0 | +0 | -2 | -1 | +0 |
| Meister Lin | – | +0 | +0 | -1 | +0 | +0 | +0 | +0 | +0 | -1 | +1 | +0 |
| Mira & Brumm | – | +0 | +0 | +0 | +0 | +0 | +0 | +0 | +0 | +0 | +0 | +0 |
| Muskelaugust |  | +0 | +0 | -1 | +0 | -2 | +0 | +0 | +0 | +2 | -0 | +0 |
| Robina |  |  |  |  |  |  | +0 | +0 | +0 | +2 | +2 | +0 |
| Robo |  | +0 | +0 | +2 | +0 | +0 | +0 | +0 | +0 | +2 | -0 | +0 |
| Ser Albrecht | – | +0 | +0 | -1 | +0 | -1 | +0 | +0 | +0 | +2 | -1 | +0 |
| Stachelia |  |  |  |  |  |  |  |  |  | +0 | +0 | +0 |
| Takeda |  | +0 | +0 | +2 | +0 | +0 | +0 | +0 | +0 | +1 | +1 | +0 |
| Wendy Wolle | – | +0 | +0 | -2 | +0 | +1 | +0 | +0 | +0 | -3 | -2 | +0 |
